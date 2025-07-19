import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

export const processPhotographerCheckIn = functions.firestore
  .document('attendance_records/{recordId}')
  .onCreate(async (snapshot, context) => {
    const record = snapshot.data();
    if (!record) {
      console.error('No attendance data found');
      return null;
    }

    if (record.type !== 'check_in') {
      console.log('Attendance record is not a check-in, skipping');
      return null;
    }

    const eventId = record.eventId;
    const photographerId = record.photographerId;
    const checkInTimestamp = record.checkInTimestamp;

    if (!eventId || !photographerId || !checkInTimestamp) {
      console.error('Missing eventId, photographerId or checkInTimestamp');
      return null;
    }

    try {
      const eventSnap = await admin.firestore().collection('events').doc(eventId).get();
      if (!eventSnap.exists) {
        console.error(`Event ${eventId} not found`);
        return null;
      }

      const event = eventSnap.data() as any;
      const eventDateTime: admin.firestore.Timestamp = event.eventDateTime;
      const requiredArrivalTimeOffsetMinutes = event.requiredArrivalTimeOffsetMinutes || 0;
      const gracePeriodMinutes = event.gracePeriodMinutes || 0;
      const lateDeductionAmount = event.lateDeductionAmount || 0;

      const requiredArrivalTime = new Date(eventDateTime.toDate().getTime() - requiredArrivalTimeOffsetMinutes * 60000);
      const gracePeriodEndTime = new Date(requiredArrivalTime.getTime() + gracePeriodMinutes * 60000);
      const checkInTime = (checkInTimestamp instanceof admin.firestore.Timestamp)
        ? checkInTimestamp.toDate()
        : new Date(checkInTimestamp);

      let isLate = false;
      let lateDeductionApplied = 0;

      if (checkInTime > gracePeriodEndTime) {
        isLate = true;
        lateDeductionApplied = lateDeductionAmount;
      }

      if (isLate) {
        await snapshot.ref.update({ isLate, lateDeductionApplied });

        const photographerRef = admin.firestore().collection('photographers_data').doc(photographerId);
        await admin.firestore().runTransaction(async (txn) => {
          const photographerSnap = await txn.get(photographerRef);
          if (!photographerSnap.exists) {
            console.error(`Photographer ${photographerId} not found`);
            return;
          }
          const currentBalance = photographerSnap.get('balance') || 0;
          const totalDeductions = photographerSnap.get('totalDeductions') || 0;
          txn.update(photographerRef, {
            balance: currentBalance - lateDeductionApplied,
            totalDeductions: totalDeductions + lateDeductionApplied,
          });
        });

        try {
          const userSnap = await admin.firestore().collection('users').doc(photographerId).get();
          const fcmToken = userSnap.exists ? userSnap.get('fcmToken') : null;
          if (fcmToken) {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: 'Late Check-In',
                body: `A deduction of ${lateDeductionApplied} has been applied for late arrival.`,
              },
            });
          }
        } catch (err) {
          console.error('Error sending FCM notification', err);
        }
      }
    } catch (error) {
      console.error('Error processing check-in', error);
    }
    return null;
  });
