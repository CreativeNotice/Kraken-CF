/**
* @displayname Kraken.io API Component
* @description You need at least a developer account for https://kraken.io. Get your API Key and Secret from https://kraken.io/account/api-credentials.
* @hint        Allows CF developers to use the Kraken.io API easily. Learn more at https://kraken.io/docs.
* @output      FALSE
* @accessors   TRUE
*
* @author      Ryan Mueller, ryanm@pjtrailers.com
* @version     1.0 11/11/2013
* @license     The MIT License (MIT)
*
* The MIT License (MIT)
* Copyright (c) 2013 Ryan Mueller
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), 
* to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
* and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
* OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
component {

	/**
	 * @displayname Kraken.io API Settings Store
	 */
	property name='settings' type='struct';


	/**
	 * @displayname Init
	 * @description You should pass your Kraken API Key and Secret in during component initialization.
	 * @param       {String} key    Your Kraken.io API key.
	 * @param       {String} secret Your Kraken.io API secret.
	 * @returntype  Void
	 */
	public function init( required string api_key, required string api_secret ){

		this.settings['auth'] = {
			'api_key'    = trim( arguments.api_key ),
			'api_secret' = trim( arguments.api_secret )
		};
	};

	/**
	 * @displayname URI
	 * @description Allows you to do an image URL based request to the API.
	 * @param       {Struct} required  opts  Pass in options. Available options documented at https://kraken.io/docs/integration-url
	 * @returntype  Any
	 */
	public function uri( required struct opts ) {

		var data = this.settings;
		structAppend( data, arguments.opts );

		return send( data, 'https://api.kraken.io/v1/url' );
	};

	/**
	 * @displayname Upload
	 * @description Allows you to pass in a file path and upload that file to Kraken.io.
	 * @param       {Struct} required  opts  Structure of API parameters. Available options documented at https://kraken.io/docs/integration-upload
	 * @returntype  Struct
	 */
	public function upload( required struct opts ) {

		// Check if file is provided
		if( ! structKeyExists(arguments.opts, 'file') ){

			return {
				'success' = FALSE,
				'error'   = 'File parameter was not provided.'
			};
		}

		// Check if file parameter is passing a url
		if( reFindNoCase('\/\/', arguments.opts.file ) ){

			arguments.opts['url'] = arguments.opts.file;
			structDelete( arguments.opts, 'file' );
			return this.uri( arguments.opts );
		}

		// Check that the file exists on disk
		if( ! fileExists( expandPath( arguments.opts.file ) ) ){

			return {
				'success' = FALSE,
				'error'   = 'File '& arguments.opts.file &' does not exist.'
			};
		}

		// Expand file path
		arguments.opts.file = expandPath( arguments.opts.file );

		// Merge options with our authentication settings
		var data = this.settings;
		structAppend( data, arguments.opts );

		return send( data, 'https://api.kraken.io/v1/upload' );
	};

	/**
	 * @displayname send
	 * @param       {String} required data JSON stringified options.
	 * @param       {String} required uri  The API endpoint to post to.
	 * @returntype  Any
	 */
	private function send( required struct data, required string uri ) {

		WriteDump( data );

		// Setup the HTTP service
		var http = new http();
		http.setMethod( 'post' );
		http.setCharset( 'utf-8' );
		http.setUrl( arguments.uri );

		// If we're uploading a file, add that as a parameter
		if( structKeyExists(arguments.data, 'file') ){
			http.addParam( type='file', name='file', file=arguments.data.file );
			structDelete( arguments.data, 'file' );			
		}

		// Add the json body
		http.addParam( type='formfield', name='fieldname', value=SerializeJson( arguments.data ) );

		// Do the request
		var result = http.send().getPrefix().filecontent.toString();

		return DeserializeJson( result );
	};
}