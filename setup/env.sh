NGINX_CLEAN_PREFIX=false

LUAJIT_ARCHIVE=LuaJIT-2.0.3.tar.gz
LUAJIT_ARCHIVE_MD5=f14e9104be513913810cd59c8c658dc0
LUAJIT=`echo $LUAJIT_ARCHIVE | awk -F".tar" '{print $1}'`
LUAROCKS_ARCHIVE=luarocks-2.2.0.tar.gz
LUAROCKS=`echo $LUAROCKS_ARCHIVE | awk -F".tar" '{print $1}'`


NGINX_ARCHIVE=nginx-1.6.2.tar.gz
NGINX=`echo $NGINX_ARCHIVE | awk -F".tar" '{print $1}'`
NGINX_DEVEL_KIT_ARCHIVE=ngx_devel_kit-0.2.19.tar.gz
NGINX_DEVEL_KIT=`echo $NGINX_DEVEL_KIT_ARCHIVE | awk -F".tar" '{print $1}'`
LUA_NGINX_ARCHIVE=lua-nginx-module-0.9.5rc2.tar.gz
LUA_NGINX=`echo $LUA_NGINX_ARCHIVE | awk -F".tar" '{print $1}'`
PCRE_ARCHIVE=pcre-8.35.tar.bz2
PCRE=`echo $PCRE_ARCHIVE | awk -F".tar" '{print $1}'`


#export LUAJIT_INC=/opt/LuaJIT-2.0.3/include/luajit-2.0
#export LUAJIT_LIB=/opt/LuaJIT-2.0.3/lib
#export NGINX_PREFIX=/Users/ccyphers/nginx-lua-1.6.2
