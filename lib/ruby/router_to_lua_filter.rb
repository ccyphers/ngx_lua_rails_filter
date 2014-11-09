module Router

  @items = []

  class << self
    # this assumes all dynamic parts of a path only contain 
    # digits. This is an assumed best practice to simplfy 
    # generating a pattern that will work with Lua, reducing 
    # the chance for bugs.
    #
    def lua_pattern(path)
      path.gsub!(/:.{1,}\//, "%d+/")
      path.gsub(/:.{1,}/, "%d+")
    end

    # we assume that callers or the Rails acpplication
    # do not reference the format such as:
    #
    # /some/path.json
    # /some/path.csv
    # /some/path.xml
    # etc...
    # 
    # Instead callers will set the Accept header
    # Accept: text/csv
    #         text/json
    #          etc...
    #
    # This is just another means for KISS
    #
    def path_without_format(i)
      i.path.spec.to_s.gsub(/\(\.:format\)/, "")
    end

    # this will be used for distinguising resources that require
    # authentication.  By using a best practice of creating 
    # controllers that end in a name _auth.rb we can simply
    # determine which paths need to be authenticated
    #
    def auth_check(i)
      controller = i.defaults[:controller] || ""
      if controller.length >5
        start_i = controller.length - 5
        end_i = controller.length - 1
        suf = controller[start_i..end_i]
        return suf == "_auth"
      end
      false
    end

    def get_methods(i)
      methods = []
      request_method = i.constraints[:request_method].to_s
      request_methods = request_method.split('|')

      if request_methods.length  == 1
        methods << request_methods.first.scan(/\^(.+)\$/).first.first
      elsif request_methods.length > 1
        methods << request_methods.first.split(/\^/).last
        methods << request_methods.pop.split(/\$/).first

        request_methods[1..request_methods.length-1].each { |m|
          methods << m.split(/\^/).last if m
        }
      end

      methods << 'GET' if methods.length == 0
      methods
    end

    def process_item(i)
      path = path_without_format(i)
      path = lua_pattern(path)

      #i.app.constraints
      auth = auth_check(i)
      i.defaults[:controller] ||= ''
      i.defaults[:action] ||= ''
      get_methods(i).each { |m|
        @items << {:method => m, :path => path, 
                   :controller => i.defaults[:controller],
                   :action => i.defaults[:action],
                   :auth_required => auth}
      }
    end

    def write
      File.open("path_info.json", "w+") do |fd|
        fd.write JSON.generate(@items)
      end
    end

    def to_lua_filter
      Rails.application.routes.router.routes.each { |i|
        process_item i
      }
      write
    end
  end
end
