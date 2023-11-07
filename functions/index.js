/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const functions = require('firebase-functions');
//const request = require('request-promise'); 
// The Firebase Admin SDK to access Firestore.
const fetch = require('node-fetch')
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {onRequest,onCall, HttpsError} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');
const {getAuth, UserRecord } = require('firebase-admin/auth')


//const clientS = functions.config().spotify.client_secret;
//const clientID = functions.config().spotify.client_id;
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started
//require('dotenv').config();
admin.initializeApp();
exports.helloWorld = onCall((request) => {
   logger.info("Hello logs!", {structuredData: true});
   return {
    text: "hello world!"
   }
});

exports.getUsersWithSameLocation = functions.https.onRequest(async (req, res) => {
  try {
    // Create a reference to the users collection
    const db = admin.firestore();
    const usersRef = db.collection('users');

    const targetLocation = req.body.location; // Assuming you are sending the location in the request body

    // Query users with the same location
    const querySnapshot = await usersRef.where('location', '==', targetLocation).get();

    const users = [];
    querySnapshot.forEach((doc) => {
      const userData = doc.data();
      const user = {
        uid: doc.id,
        songs: userData.songs || [], // Assuming 'songs' is an array
      };
      users.push(user);
    });

    // Send the response as JSON
    res.json({ users });
  } catch (error) {
    console.error('Error getting users:', error);
    res.status(500).json({ error: error.message });
  }
});

exports.generateCustomToken = functions.https.onRequest(async (req, res) => {
  try {
    const { uid, spotifyAccessToken } = req.body; // Get UID and Spotify access token from the request body

    // Verify the Spotify access token if needed
    // ...

    const customToken = await admin.auth().createCustomToken(uid);
    
    res.status(200).json({ customToken });
  } catch (error) {
    console.error('Error generating custom token:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

exports.authToken = functions.https.onCall(async (data, context) => {
  const clientId = functions.config().spotify.client_id;
  const clientSecret = functions.config().spotify.client_secret;

  try {
    const tokenUrl = 'https://accounts.spotify.com/api/token';
    const requestBody = new URLSearchParams();
    requestBody.append('grant_type', 'authorization_code');
    requestBody.append('code', data.code);
    requestBody.append('redirect_uri', data.redirect_uri);

    const response = await fetch(tokenUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: requestBody
    });

    if (!response.ok) {
      throw new Error('Failed to get access token from Spotify');
    }

    const tokenData = await response.json();
    const accessToken = tokenData.access_token;
    const refreshToken = tokenData.refresh_token

    const userInfoResponse = await fetch("https://api.spotify.com/v1/me", {
      method: "GET",
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    });

    if (!userInfoResponse.ok) {
      throw new Error('Failed to fetch user info from Spotify');
    }

    const userInfo = await userInfoResponse.json();
    const uid = userInfo.id;

    const customToken = await admin.auth().createCustomToken(uid);
    await admin.firestore().collection("users").doc(uid).set({"accessToken": accessToken,"refreshToken":refreshToken},{merge:true})
    return {
      access_token: accessToken,
      fire_token: customToken,
      id: uid
    };
  } catch (error) {
    console.error(error);
    return { error: error.message };
  }
});
// Define your Cloud Function
exports.getSong = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new HttpsError('unauthenticated', 'User is not authenticated');
    }

    const userId = context.auth.uid;
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User data not found');
    }


    const { accessToken, refreshToken, songs} = userDoc.data();

    const userInfoResponse = await fetch(`https://api.spotify.com/v1/tracks/${data.songID}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!userInfoResponse.ok) {
      if (userInfoResponse.status === 401) {
          const refreshedAccessToken = await refreshAccessToken(refreshToken, userId)
          const refreshedUserInfoResponse = await fetch(`https://api.spotify.com/v1/tracks/${data.songID}`, {
            method: 'GET',
            headers: {
              Authorization: `Bearer ${refreshedAccessToken}`,
            },
          });

          if (refreshedUserInfoResponse.ok) {
            const refreshedUserInfo = await refreshedUserInfoResponse.json();
            return refreshedUserInfo
              
          }
        }
        else{
          throw new HttpsError('internal', 'Failed to fetch user info from Spotify');
        }
    }
    const userInfo = await userInfoResponse.json();
    return userInfo
  } catch (error) {
      console.error(error);
      throw new HttpsError('internal', error.message);
  }
});



exports.getUserInfo = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new HttpsError('unauthenticated', 'User is not authenticated');
    }

    const userId = context.auth.uid;
    const userRef = admin.firestore().collection('users').doc(userId);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      throw new HttpsError('not-found', 'User data not found');
    }


    const { accessToken, refreshToken, songs} = userDoc.data();

    const userInfoResponse = await fetch('https://api.spotify.com/v1/me', {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!userInfoResponse.ok) {
      if (userInfoResponse.status === 401) {
          const refreshedAccessToken = await refreshAccessToken(refreshToken, userId)
          const refreshedUserInfoResponse = await fetch('https://api.spotify.com/v1/me', {
            method: 'GET',
            headers: {
              Authorization: `Bearer ${refreshedAccessToken}`,
            },
          });

          if (refreshedUserInfoResponse.ok) {
            const refreshedUserInfo = await refreshedUserInfoResponse.json();
            return {
              uid: userId,
              href: refreshedUserInfo.href,
              images: refreshedUserInfo.images[0],
              display_name: refreshedUserInfo.display_name,
              songs : songs
            };
          }
        }
        else{
          throw new HttpsError('internal', 'Failed to fetch user info from Spotify');
        }
    }
    const userInfo = await userInfoResponse.json();
    return {
      uid: userId,
      href: userInfo.href,
      images: userInfo.images[0],
      display_name: userInfo.display_name,
      songs: songs
    };
  } catch (error) {
      console.error(error);
      throw new HttpsError('internal', error.message);
  }
});

async function refreshAccessToken(refreshToken, userId){
  const clientId = functions.config().spotify.client_id;
  const clientSecret = functions.config().spotify.client_secret;
  const authOptions = {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${clientId}:${clientSecret}`).toString('base64')}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=refresh_token&refresh_token=${refreshToken}`,
  };

  const authResponse = await fetch('https://accounts.spotify.com/api/token', authOptions);

  if (!authResponse.ok) {
    throw new HttpsError('internal', 'Failed to refresh access token');
  }
  else{
    const authData = await authResponse.json();
    await admin.firestore().collection('users').doc(userId).update({
            accessToken: authData.access_token,
          });
    return authData.access_token
  }
}

exports.uploadGeoHash = functions.https.onCall(async (data, context) => {
  try {
    // Get the UID of the authenticated user
    const userId = context.auth.uid;

    // Reference the "users" collection and add a new document
    const userRef = admin.firestore().collection('users').doc(userId);
    console.log(`UID: ${userId}`);
    console.log(`GeoHash: ${data.geoHash}`);
     try {
        const snapshot = await admin.firestore().collection('users').get(); // Replace 'your-collection' with the name of your Firestore collection
        snapshot.forEach((doc) => {
          console.log('Document ID:', doc.id, 'Data:', doc.data());
        });
      } catch (error) {
        console.error('Error reading Firestore data:', error);
      }
    // Set the data for the new document
    await userRef.set({
      location: `${data.geoHash}`,
    });
    
    return { success: true };
  } catch (error) {
    console.error('Error uploading GeoHash:', error);
    throw new functions.https.HttpsError('internal', 'Error uploading GeoHash');
  }
});

