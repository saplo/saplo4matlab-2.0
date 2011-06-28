% 1) Add your API Key & Secret Key to the function saploRequest
% 2) Check out Saplo API Documentation @ http://developer.saplo.com
% 3) Make Request according to the documentation method names and params as
% following example: 
% 
% params.name = 'My Collection Name'
% params.language = 'en'
% response = saploRequest('collection.create', params)
% response.collection_id
%

function saploclient()
    dbstop if error;
    
    % List collections
    response = saploRequest('collection.list');
    
    if length(response) == 0
    
        % 1) Create your collection
        params.name = 'My First Collection';
        params.language = 'en';
        response = saploRequest('collection.create', params);
        collectionId = response.collection_id
        sprintf('Collection id %s \n', collectionId);
    
        % 2) Add a text
        params = ''
        params.headline = 'Sweden from Wikipedia';
        params.body = 'Sweden shares borders with Norway to the west and Finland to the east, and is connected to Denmark by ?resund Bridge.';
        params.collection_id = collectionId;
        response = saploRequest('text.create', params)
        textId = response.text_id;
        sprintf('Text id %s \n', textId);

        % 3) Get tags
        params = ''
        params.collection_id = collectionId;
        params.text_id = textId;
        params.wait = 10;
        response = saploRequest('text.tags', params);
        sprintf('First tag is: %s  \n', response.tags{1}.tag);
    end
end


function responseStruct = saploRequest(method, params, token)
    
    
    apiKey = '' %PROVIDE YOUR API KEY
    secretKey = '' %PROVIDE YOUR SECRET KEY
    
    %Endpoint baseurl to Saplo API
    baseurl = 'https://api.saplo.com/rpc/json'; 
    
    % Set default params if none is provided
    % If no token is provided we will authenticate with Saplo API before
    % making any request.
    if nargin < 3
       token = saploAuth(baseurl, apiKey, secretKey);
    end
    if nargin < 2
        params =  struct([]);
    end
    
    url = [baseurl, '?access_token=', token] %Add access token to url
    
    request.method = method;    %Method that will be called
    request.params = params;    %Request params
    request.jsonrpc = '2.0';    %Version to use (standard)
    json = mat2json(request);   %Convert struct to json
    
    response = urlreadX(url, 'POSTX', json); %Make HTTP Post to URL
    responseStruct = parseResponse(response)
end


%%%%
% Parse the JSON response received from Saplo API and convert it to a
% struct. Checking if an error is raised otherwise return the response
% struct.
%%%%
function responseStruct = parseResponse(response)

    
    
    response = parse_json(response);    %Convert json to struct
    
    % Handle response from Saplo API
    if isfield(response{1},'error')
        errStr = ['SaploError: (', num2str(response{1}.error.code) ,') ', response{1}.error.msg];
        err = MException('ResultChk:OutOfRange', errStr);
        throw(err)
    elseif isfield(response{1},'result')
        responseStruct = response{1}.result;
    else
       errStr = 'SaploError: Server is not responding.';
       err = MException('ResultChk:OutOfRange', errStr);
       throw(err)
    end
end

function token = saploAuth(url, apiKey, secretKey)
    
    request.method = 'auth.accessToken'; %Method that will be called
    request.params.api_key = apiKey; %Request params
    request.params.secret_key = secretKey; %Request params
    request.jsonrpc = '2.0'; %Version to use (standard)
    json = mat2json(request); %Convert struct to json
    
    response = urlreadX(url, 'POSTX', json); %Make HTTP Post to URL
    responseStruct = parseResponse(response)
    token = responseStruct.access_token

end


function [output,status] = urlreadX(urlChar,method,params)
    %URLREAD Returns the contents of a URL as a string.
    %   S = URLREAD('URL') reads the content at a URL into a string, S.  If the
    %   server returns binary data, the string will contain garbage.
    %
    %   S = URLREAD('URL','method',PARAMS) passes information to the server as
    %   part of the request.  The 'method' can be 'get', or 'post' and PARAMS is a 
    %   cell array of param/value pairs.
    %
    %   [S,STATUS] = URLREAD(...) catches any errors and returns 1 if the file
    %   downloaded successfully and 0 otherwise.
    %
    %   Examples:
    %   s = urlread('http://www.mathworks.com')
    %   s = urlread('ftp://ftp.mathworks.com/README')
    %   s = urlread(['file:///' fullfile(prefdir,'history.m')])
    % 
    %   From behind a firewall, use the Preferences to set your proxy server.
    %
    %   See also URLWRITE.

    %   Matthew J. Simoneau, 13-Nov-2001
    %   Copyright 1984-2008 The MathWorks, Inc.
    %   $Revision: 1.3.2.10 $ $Date: 2008/10/02 18:59:57 $
    
    
    % Modified by Saplo. Added a way of sending POST data. Uses the method
    % 'POSTX'. 

    % This function requires Java.
    if ~usejava('jvm')
       error('MATLAB:urlread:NoJvm','URLREAD requires Java.');
    end

    import com.mathworks.mlwidgets.io.InterruptibleStreamCopier;

    % Be sure the proxy settings are set.
    com.mathworks.mlwidgets.html.HTMLPrefs.setProxySettings

    % Check number of inputs and outputs.
    error(nargchk(1,3,nargin))
    error(nargoutchk(0,2,nargout))
    if ~ischar(urlChar)
        error('MATLAB:urlread:InvalidInput','The first input, the URL, must be a character array.');
    end
    if (nargin > 1) && ~strcmpi(method,'get') && ~strcmpi(method,'post') && ~strcmpi(method,'postx')
        error('MATLAB:urlread:InvalidInput','Second argument must be either "get" or "post".');
    end

    % Do we want to throw errors or catch them?
    if nargout == 2
        catchErrors = true;
    else
        catchErrors = false;
    end

    % Set default outputs.
    output = '';
    status = 0;

    % GET method.  Tack param/value to end of URL.
    if (nargin > 1) && strcmpi(method,'get')
        if mod(length(params),2) == 1
            error('MATLAB:urlread:InvalidInput','Invalid parameter/value pair arguments.');
        end
        for i=1:2:length(params)
            if (i == 1), separator = '?'; else separator = '&'; end
            param = char(java.net.URLEncoder.encode(params{i}));
            value = char(java.net.URLEncoder.encode(params{i+1}));
            urlChar = [urlChar separator param '=' value];
        end
    end

    % Create a urlConnection.
    [urlConnection,errorid,errormsg] = urlreadwriteX(mfilename,urlChar);
    if isempty(urlConnection)
        if catchErrors, return
        else error(errorid,errormsg);
        end
    end

    % POST method.  Write param/values to server.
    if (nargin > 1) && strcmpi(method,'post')
        try
            urlConnection.setDoOutput(true);
            urlConnection.setRequestProperty( ...
                'Content-Type','application/x-www-form-urlencoded');
            printStream = java.io.PrintStream(urlConnection.getOutputStream);
            for i=1:2:length(params)
                if (i > 1), printStream.print('&'); end
                param = char(java.net.URLEncoder.encode(params{i}));
                value = char(java.net.URLEncoder.encode(params{i+1}));
                printStream.print([param '=' value]);
            end
            printStream.close;
        catch
            if catchErrors, return
            else error('MATLAB:urlread:ConnectionFailed','Could not POST to URL.');
            end
        end
    end

    % POSTX method.  Write param/values to server.
    if (nargin > 1) && strcmpi(method,'postx')
        try
            urlConnection.setDoOutput(true);
            urlConnection.setRequestProperty('Content-Type','application/x-www-form-urlencoded');
            printStream = java.io.PrintStream(urlConnection.getOutputStream);
            printStream.print(params);
            printStream.close;
        catch
            if catchErrors, return
            else error('MATLAB:urlread:ConnectionFailed','Could not POST to URL.');
            end
        end
    end



    % Read the data from the connection.
    try
        inputStream = urlConnection.getInputStream;
        byteArrayOutputStream = java.io.ByteArrayOutputStream;
        % This StreamCopier is unsupported and may change at any time.
        isc = InterruptibleStreamCopier.getInterruptibleStreamCopier;
        isc.copyStream(inputStream,byteArrayOutputStream);
        inputStream.close;
        byteArrayOutputStream.close;
        output = native2unicode(typecast(byteArrayOutputStream.toByteArray','uint8'),'UTF-8');
    catch
        if catchErrors, return
        else error('MATLAB:urlread:ConnectionFailed','Error downloading URL. Your network connection may be down or your proxy settings improperly configured.');
        end
    end
end

function [urlConnection,errorid,errormsg] = urlreadwriteX(fcn,urlChar)
    %URLREADWRITE A helper function for URLREAD and URLWRITE.

    %   Matthew J. Simoneau, June 2005
    %   Copyright 1984-2007 The MathWorks, Inc.
    %   $Revision: 1.1.6.3.6.1 $ $Date: 2009/01/30 22:37:42 $

    % Default output arguments.
    urlConnection = [];
    errorid = '';
    errormsg = '';

    % Determine the protocol (before the ":").
    protocol = urlChar(1:min(find(urlChar==':'))-1);

    % Try to use the native handler, not the ice.* classes.
    switch protocol
        case 'http'
            try
                handler = sun.net.www.protocol.http.Handler;
            catch exception %#ok
                handler = [];
            end
        case 'https'
            try
                handler = sun.net.www.protocol.https.Handler;
            catch exception %#ok
                handler = [];
            end
        otherwise
            handler = [];
    end

    % Create the URL object.
    try
        if isempty(handler)
            url = java.net.URL(urlChar);
        else
            url = java.net.URL([],urlChar,handler);
        end
    catch exception %#ok
        errorid = ['MATLAB:' fcn ':InvalidUrl'];
        errormsg = 'Either this URL could not be parsed or the protocol is not supported.';
        return
    end

    % Get the proxy information using MathWorks facilities for unified proxy
    % prefence settings.
    mwtcp = com.mathworks.net.transport.MWTransportClientPropertiesFactory.create();
    proxy = mwtcp.getProxy(); 


    % Open a connection to the URL.
    if isempty(proxy)
        urlConnection = url.openConnection;
    else
        urlConnection = url.openConnection(proxy);
    end
end
