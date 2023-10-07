/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
//const functions = require('firebase-functions');

// The Firebase Admin SDK to access Firestore.
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
//const clientS = functions.config().spotify.client_secret;
//const clientID = functions.config().spotify.client_id;
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.helloWorld = onRequest((request, response) => {
   logger.info("Hello logs!", {structuredData: true});
   response.send("Hello from Firebase!");
});

/*exports.auth = onRequest(async (req, res) => {
   
   var authOptions = {
      url: 'https://accounts.spotify.com/api/token',
      form: {
        code: req.query.code,
        redirect_uri: req.query.redirect_uri,
        grant_type: 'authorization_code'
      },
      headers: {
        'Authorization': 'Basic ' + (new Buffer.from(clientID + ':' + clientS).toString('base64'))
      },
      json: true
    };
    request.post(authOptions, async function(error, response, body) {
    if (!error && response.statusCode === 200) {
      var access_token = body.access_token;
      var expires_in = body.expires_in
      var refresh_token = body.refresh_token
      const writeTokens = await getFirestore()
        .collection("users").document(req.uID)
        .setData([ "access_token": access_token, "refresh_token": refresh_token, expires_in:"expires_in" ], merge: true) 
      res.send({
        'access_token': access_token
      });
    }
    else{
        res.send({
            'error':error
        })
    }
  });
   
});*/

/*exports.addlocation = onRequest((request, response) => {
    const original = req.query.text;
    const user = req.query.uID;
  // Push the new message into Firestore using the Firebase Admin SDK.
  const writeResult = await getFirestore()
      .collection("users")
      .add({original: original});
  // Send back a message that we've successfully written the message
  res.json({result: `Message with ID: ${writeResult.id} added.`});
});*/
