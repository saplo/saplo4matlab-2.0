Client Library for using Matlab with Saplo Text Analysis API 2.0

A) Read more about Saplo Text Analysis API on http://saplo.com/api
B) API Documentation is found on http://developer.saplo.com
C) Signup for a free API key on http://saplo.com/signup
D) Add your API Key & Secret Key to the function saploRequest in jsonclient.m
E) Make Request according to the documentation method names and params as following example:

	params.name = 'My Collection Name'
	params.language = 'en'
	response = saploRequest('collection.create', params)
	response.collection_id
	

Basically there is just one function that you need to know of. The function saploRequest takes 3 arguments.

1) the Saplo API method you want to use. These are found on our <a href="http://developer.saplo.com">API documentation site</a>.
2) the parameters that the method takes. These are created as a struct.
3) the access token that was created when authorizing with the API. If you don't provide a token the client handles it by it self (authorizing before making the request) but if you are creating a larger application with many calls after each other it's good to provide the token as a param, then no time is wasted on authorization.