#NGX_LUA_RAILS_FILTER

## Overview


If you use Nginx as the first layer to your Rails stack, you already appreciate the threaded event driven capabilities of a high performant HTTP Server.  Want to squeese out the upmost in performance from your Rails application?

By filtering out bad request at the Nginx layer, you free your Rails stack up to process valid request.  For every bad request that has to be processed by rails, adds delay to end users using your application.

Whether you want to filter out request which are not valid rails routes, or return a 401 for resources requiring a user to login, **NGX_LUA_RAILS_FILTER**, is here to help.

## Rails assumptions

### Authenticated Resources

Following convention over configuration, if you need to authenticate a resource, the controller name should end in \_auth.  Using the _auth naming convention, reduces the complexity to know when a resource requires authentication.  For example, say you have routes defined as:

    get 'public/home' => 'home#index'
    get 'home' => 'home_auth#index'
    
The route /home would require a user to be authenticated since the controller that processing the action ends in _auth.

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


### Filtering based on Routes

    lib/lua/path_filter.lua

Provides the means for returning a 404 when a request path does not match a rails route.  Keeping with the KISS principle, all dynamic routes should comply with the constraint /\d{,}/.  By having all dynamic rails routes matching to digits only, reduces the complexity in converting the rails route to a Lua pattern.  You will also need to restrain from using the format option of Rails.  Instead of using format, ensure that clients set the Accept header.  

For example:

    PATH /some/api/v1/call.json
    
Should be:

    Header
      Accept: text/json
    PATH /some/api/v1/call
    
By setting the Accept header, Rails can process the respond_to just the same as if you used the format option in the path.

When 
     path_filter:perform()

is called, it compares the path in the request against all items in the path_info.json strucgure.  If a match isn't found it halts Nginx processing of the request:

    ngx.status = 404
    ngx.exit(ngx.HTTP_NOT_FOUND)
  
 

## Setup

Info will follow on setting Nginx + lua up.  In the mean time you might want to review setup/*.sh

