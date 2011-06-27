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