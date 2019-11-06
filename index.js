/**
 * This sample demonstrates how to call Box APIs from a Lambda function using the Box Node SDK.
 *
 * For step-by-step instructions on how to create and authorize a Box application,
 * see https://github.com/box/samples/tree/master/box-node-lambda-sample.
 */

'use strict';

const BoxSDK = require('box-node-sdk');

// Load the config from an environment variable for security and configuration management.
const boxConfig = JSON.parse(process.env.BOX_CONFIG);

const sdk = BoxSDK.getPreconfiguredInstance(boxConfig); 

/**
 * Create a service account client that performs actions in the context of the specified
 * enterprise.  The app has a unique service account in each enterprise that authorizes the app.
 * The service account contains any app-specific content for that enterprise.
 * Depending on the scopes selected, it can also create and manage app users or managed users
 * in that enterprise.
 *
 * The client will automatically create and refresh the service account access token, as needed.
 */
const client = sdk.getAppAuthClient('enterprise');

/**
 *  YOUR CODE GOES HERE!!!
 *
 *  This sample function returns details of the current user (the service account).
 */
client.enterprise.addUser(null, 'Test Admin', {is_platform_access_only: true}, (err, result) => {
	
});

exports.downloader = (filename, context, callback) => {
    var fs = require('fs');
    client.folders.create(0, '', (err, result) => {...});
    client.folders.getItems(0, null, (err, result) => {...});
    // Get file differences
    // 					       
	   // if (error) {
		    // handle error
	   // }

	// write the file to disk
	var output = fs.createWriteStream('/path/to/file');
	stream.pipe(output);
});    
}

exports.handler = (event, context, callback) => {
    console.log(`Event: ${JSON.stringify(event, null, 2)}`);

    // Get details on the current user  (the service account)
    client.users.get(client.CURRENT_USER_ID, null, (err, result) => {
        let response;

        if (err) {
            if (err.response && err.response.body) {
                response = err.response.body;
            } else {
                response = err.toString();
            }
        } else {
            response = result;
        }

        console.log(`Response: ${JSON.stringify(response, null, 2)}`);
        callback(null, response);
    });
};
