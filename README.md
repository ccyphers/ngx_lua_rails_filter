#NGX_LUA_RAILS_FILTER

## Overview


If you use Nginx as the first layer to your Rails stack, you already appreciate the threaded event driven capabilities of a high performant HTTP Server.  Want to squeese out the upmost in performance from your Rails application?

By filtering out bad request at the Nginx layer, you free your Rails stack up to process valid request.  For every bad request that has to be processed by rails, adds delay to end users using your application.

Whether you want to filter out request which are not valid rails routes, or return a 401 for resources requiring a user to login, **NGX_LUA_RAILS_FILTER**, is here to help.

## Features


### Filtering based on Rails Routes

If you want Nginx to send responses back to the client for paths that do not match a valid Rails route simply add configuration to the http stansa for nginx.conf:

    http {
        lua_package_path '$prefix/?.lua;;';
        init_by_lua '
            loadfile("string_ext.lua")()
            path_filter = require("path_filter"):new({path_info_json = "/somepath/path_info.json"})
            
        ';
    ...
    ...
    }
    
And in the block where you define your server's location:

    ...
    location / {
        access_by_lua '
          path_filter:perform()
        ';
        proxy_pass http://yourrailsapp
    ...

When a request is processed if the request does not match a valid rails route a 404 is returned.  

#### Assumtpions

* Dynamic routes should be constrained to /\d{,}/,  in order to translate the Rails Route into a Lua pattern.
* You need to skip using the format option in a path, this means instead of making API calls using:

      GET /some/api/v1/call.json
       
     set the accept header:
    
      Accept: text/json
      GET /some/api/v1/call
      
    This allows all controller actions to function the same when using the respond_to format options, in case you need to return different data based on HTML, JSON, XML, CSV, etc...  Just make sure that the accept header value matches the appropriate format based on mime type.
      

### Authenticated Resources

Following convention over configuration, if you need to authenticate a resource, the controller name should end in \_auth.  Using the _auth naming convention, it makes it trivial for Lua to know when a path being processed by Nginx requires a valid user authentication.  

For example, say you have routes defined as:

    get 'public/home' => 'home#index'
    get 'home' => 'home_auth#index'
    
The route /home would require a user to be authenticated since the controller that processing the action ends in _auth.

Multiple phases are used in determining information about a user's session.  The first level of defense, is a raw session decrytpion directly in Lua, and if there isn't a valid session, directly returning a 401.  The Lua code under lib/lua/session.lua, performs the same logic as rails in verifying the integrety of the session data then decrypting the session.  The second phase of verification is a shared Redis cache for session data.  Your rails application should set a cache key at the time a user logs in.  If you are using devise, overwirte the sign_in method in the ApplicationController:


    def sign_in(*args)
      super(*args)
      r = Redis.new
      r.set(session.id, {:user_id => current_user.id, 
                         :signin_at  => current_user.current_sign_in_at.tv_sec}.to_json)
    end

Then create a sessions controller to handle login/logout.  In the sessions controller for the login:

    u = User.where(condition based on email, username, etc).first
    if u
      if u.valid_password?(params[:password])
        sign_in u
        render what ever type of data you need
        return
      end
    end
    
    render some error code for client
    

Now that the session_id and the time the user logged in in Redis, the session.lua code can verify that the current request's session_id is found in the Redis cache.  You can perform action such as restricting the session duration based on a time constraint by comparing the current time with that of the cached signed_at.  You should also have hooks in devise that clear the Redis cache when a session is invalidated.

#### Sample Nginx Config

First you will need to get some information from your Rails appcation used in verifiying and decrypting the cookie data:

Encrption Password:

    /rails/root/config/secret.yml
Signer/Verification Salt: 

    Rails.configuration.action_dispatch.encrypted_signed_cookie_salt
Encryption Salt:

    Rails.configuration.action_dispatch.encrypted_cookie_salt
    

nginx.conf

    ...
    ...
    http {
        lua_package_path '$prefix/?.lua;;';
        init_by_lua '
  
          local session = require("session"):new({cookie_name = "_your_application_name_session", salt = "encrypted cookie", sign_salt = "signed encrypted cookie", password = "password from rails"})
          loadfile(""string_ext.lua")()
          path_filter = require("path_filter"):new({session = session, path_info_json = "/somepath/path_info.json"})

        ';
    ...
    ...
    }
    
    
And in the block where you define your server's location:

    ...
    location / {
        access_by_lua '
          -- match will contain the path object with slots
          -- method
          -- path
          -- auth_required
          match = path_filter:perform()
          
          -- If the path object indicates auth_required
            -- the handle_auth cookie session data
            -- And compares with Redis cache
            -- If the user is allowed access
            -- do nothing
            -- else
            -- Return a 401
          path_filter:handle_auth(match)

        ';
        proxy_pass http://yourrailsapp
    ...




### Turning Rails routes to JSON

A utility has been provided that turns rails routs into JSON, for the Lua filtering:

    lib/ruby/router_to_lua_filter.rb

From your rails root, you can execute:

    ruby -r <path to ngx_lua_rails_filter>/lib/rubyrouter_to_lua_filter.rb bin/rails runner Router.to_lua_filter
    
Which will generate a file called:

    path_info.json

####path_info.json structure

The JSON represents an array of objects where the object has properties:

* method
* path
* auth_required

For example:

    [
      {
        "method":"GET",
        "path":"/assets",
        "auth_required":false
      },
      { 
        "method":"POST",
        "path":"/login",
        "auth_required":false
      },
      {
        "method":"GET",
        "path":"/logout",
        "auth_required":false
      },
      {
        "method":"GET",
        "path":"/public/home",
        "auth_required":false
      },
      {
        "method":"GET",
        "path":"/home",
        "auth_required":true
      }
    ]

 

## Setup

For personal use, I compile just what I need into Nginx, instead of using something like [OpenResty](https://github.com/openresty).  However, the OpenResty team is doing good work in bringing a full blown application server directly into Nginx via Lua scripting.

If you want to compile Nginx with Lua support, without the OpenResty framework, feel free to use setup/install.sh:

Each line below is the combination of arguments required to perform a task.  You can combine multiple task together

    
--install-luajit --luajit-prefix /some/prefix --tmp-dir /tmp

--install-luarocks --luajit-prefix /prefix/used/for/install-luajit --tmp-dir /tmp

--install-nginx --nginx-prefix /some/prefix --luajit-prefix /prefix/used/for/install-luajit --tmp-dir /tmp

