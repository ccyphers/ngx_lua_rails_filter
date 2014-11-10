BASE=`dirname $0`
. $BASE/env.sh
NUM_COMMANDS=0

usage() {
  echo "Each line below is the combination of arguments 
  required to perform a task.  You can combine multiple task together

  "

  echo "install.sh plus a command with options:
  
  "

  echo "--install-luajit --luajit-prefix /some/prefix --tmp-dir /tmp"
  echo "--install-luarocks --luajit-prefix /prefix/used/for/install-luajit --tmp-dir /tmp"
  echo "--install-nginx --nginx-prefix /some/prefix --luajit-prefix /prefix/used/for/install-luajit --tmp-dir /tmp"

}

process_arg() {

  arg=`echo "$*" | awk '{print $1}'`
  #echo "ARG: $arg"
  case "$arg" in

    "--luajit-prefix")
      shift
      LUAJIT_PREFIX=`echo "$*" | awk '{print $1}'`
      d=`dirname $LUAJIT_PREFIX`
      if [ ! -d $d ] ; then
        echo "Could not find the base for LUAJIT_PREFIX: $d"
        exit 1
      fi
      export LUAJIT_INC=$LUAJIT_PREFIX/include/luajit-2.0
      export LUAJIT_LIB=$LUAJIT_PREFIX/lib
      ;;

    "--install-luajit")
      COMMANDS[$NUM_COMMANDS]="install_lua"
      let NUM_COMMANDS=$NUM_COMMANDS+1
      ;;

    "--install-luarocks")
      COMMANDS[$NUM_COMMANDS]="install_luarocks"
      let NUM_COMMANDS=$NUM_COMMANDS+1
      ;;

    "--install-nginx")
      COMMANDS[$NUM_COMMANDS]="install_nginx"
      let NUM_COMMANDS=$NUM_COMMANDS+1
      ;;

    "--install-lua-libs")
      COMMANDS[$NUM_COMMANDS]="install_lua_libs"
      let NUM_COMMANDS=$NUM_COMMANDS+1
      ;;

    "--nginx-clean-prefix")
      NGINX_CLEAN_PREFIX=true
      ;;

    "--nginx-prefix")
      shift
      NGINX_PREFIX=`echo "$*" | awk '{print $1}'`
      d=`dirname $NGINX_PREFIX`
      if [ ! -d $d ] ; then
        echo "Could not find the base for NGINX_PREFIX: $d"
        usage
        exit 1
      fi
      ;;

    "--lua-include")
      shift
      LUAJIT_INC=`echo "$*" | awk '{print $1}'`
      if [ ! -d $LUAJIT_INC ] ; then
        echo "Could not find LUAJIT_INC dir at: $LUAJIT_INC"
        exit 1
      fi
      ;;

    "--lua-lib")
      shift
      LUAJIT_LIB=`echo "$*" | awk '{print $1}'`
      if [ ! -d $LUAJIT_LIB ] ; then
        echo "Could not find LUAJIT_LIB dir at: $LUAJIT_LIB"
        exit 1
      fi
      ;;

    "--tmp-dir")
      shift
      TMP_DIR=`echo "$*" | awk '{print $1}'`

      if [ ! -d $TMP_DIR ] ; then
        echo "Could not find tmp dir at: $dir"
        exit 1
      fi
      ;;

    "--nginx-config-dir")
      shift
      NGINX_CONFIG_DIR=`echo "$*" | awk '{print $1}'`

      if [ ! -d $NGINX_CONFIG_DIR ] ; then
        echo "Could not find nginx config dir: $NGINX_CONFIG_DIR"
        exit 1
      fi

      if [ ! -f $NGINX_CONFIG_DIR/conf/nginx.conf ] ; then
        echo "Could not find $NGINX_CONFIG_DIR/conf/nginx.conf"
        exit 1
      fi
      ;;

    "--copy-nginx-config")
      COMMANDS[$NUM_COMMANDS]="set_config"
      let NUM_COMMANDS=$NUM_COMMANDS+1
      ;;
  esac
}


process_args() {
  while [ "$*" != "" ] ; do
    process_arg $*
    shift
  done

  if [ $NUM_COMMANDS -eq 0 ] ; then
    echo "Could not find a command to execute"
    usage
    exit 1
  fi
  #echo ${COMMANDS[@]}

  ct=0
  while [ $ct -lt $NUM_COMMANDS ] ; do
    echo ${COMMANDS[$ct]}
    ${COMMANDS[$ct]}
    let ct=$ct+1
  done



#  if [ "$LUAJIT_INC" = "" ] ; then
#    echo "Missing --lua-include"
#    exit 1
#  fi

}

enforce_tmp_dir() {
  if [ "$TMP_DIR" = "" ] ; then
    echo "Could not find TMP dir:  use --tmp-dir to set the location for
    building required dependencies"
    exit 1
  fi
}


extract() {
  cd $BASE
  tar -xzf nginx-1.6.2.tar.gz
  tar -xjf pcre-8.35.tar.bz2
  tar -xzf openssl-1.0.1i.tar.gz
  tar -xzf LuaJIT-2.0.3.tar.gz
}

install_lua() {
  if [ "$LUAJIT_PREFIX" = "" ] ; then
    echo "Could not find LuaJIT install prefix."
    echo "Provide a prefix to intall LuaJIT to with --luajit-prefix"
    exit 1
  fi

  enforce_tmp_dir

  if [ ! -f $TMP_DIR/$LUAJIT_ARCHIVE ] ; then
    curl $LUAJIT_DOWNLOAD > /tmp/$LUAJIT_ARCHIVE
  fi

  d=$TMP_DIR/$LUAJIT

  tar -C $TMP_DIR -xzf $TMP_DIR/$LUAJIT_ARCHIVE
  cd $d

  sed -e "s@PREFIX=.*@PREFIX=$LUAJIT_PREFIX@g" Makefile > Makefile.tmp
  mv Makefile.tmp Makefile
  make && make install
  ln -s $LUAJIT_PREFIX/bin/luajit $LUAJIT_PREFIX/bin/lua
}

install_luarocks() {
  enforce_tmp_dir

  if [ "$LUAJIT_PREFIX" = "" ] ; then
    echo "Missing --luajit-prefix"
    exit 1
  fi

  if [ ! -f $TMP_DIR/$LUAROCKS_ARCHIVE ] ; then
    curl $LUAROCKS_DOWNLOAD > /tmp/$LUAROCKS_ARCHIVE
  fi


  export PATH=$LUAJIT_PREFIX/bin:$PATH

  cd $TMP_DIR
  tar -xzf $LUAROCKS_ARCHIVE
  cd $LUAROCKS
  ./configure --with-lua-include=$LUAJIT_INC
  make && make install
}

enforce_nginx_prefix() {
  if [ "$NGINX_PREFIX" = "" ] ; then
    echo "Missing --nginx-prefix"
    exit 1
  fi


}

install_nginx() {
  if [ "$LUAJIT_PREFIX" = "" ] ; then
    echo "Missing --luajit-prefix"
    exit 1
  fi


  enforce_tmp_dir
  enforce_nginx_prefix

  if [ ! -f $TMP_DIR/$NGINX_ARCHIVE ] ; then
    curl $NGINX_DOWNLOAD > /tmp/$NGINX_ARCHIVE
  fi


  if [ ! -f $TMP_DIR/$PCRE_ARCHIVE ] ; then
    curl $PCRE_DOWNLOAD > /tmp/$PCRE_ARCHIVE
  fi

  if [ ! -f $TMP_DIR/$NGINX_DEVEL_KIT_ARCHIVE ] ; then
    curl $NGINX_DEVEL_KIT_DOWNLOAD > /tmp/$NGINX_DEVEL_KIT_ARCHIVE
  fi

  if [ ! -f $TMP_DIR/$NGINX_DEVEL_KIT_ARCHIVE ] ; then
    curl $NGINX_DEVEL_KIT_DOWNLOAD > /tmp/$NGINX_DEVEL_KIT_ARCHIVE
  fi

  if [ ! -f $TMP_DIR/$LUA_NGINX_ARCHIVE ] ; then
    curl $LUA_NGINX_DOWNLOAD > /tmp/$LUA_NGINX_ARCHIVE
  fi


  cd $TMP_DIR

  tar -xzf $NGINX_ARCHIVE
  tar -xjf $PCRE_ARCHIVE
  tar -xzf $NGINX_DEVEL_KIT_ARCHIVE
  tar -xzf $LUA_NGINX_ARCHIVE

  cd $TMP_DIR/$NGINX

  ./configure --prefix=$NGINX_PREFIX \
    --with-pcre=$TMP_DIR/$PCRE \
    --with-cc-opt="-Wno-deprecated-declarations" \
    --add-module=$TMP_DIR/$NGINX_DEVEL_KIT \
    --add-module=$TMP_DIR/$LUA_NGINX \
    --with-http_auth_request_module #\
    #--with-debug

  if [ "$NGINX_CLEAN_PREFIX" = "true" ] ; then
    rm -rf $NGINX_PREFIX
  fi
  make -j2 && make install
}

install_lua_libs() {
  enforce_nginx_prefix
  cp $BASE/../lib/lua/*.lua $NGINX_PREFIX/
  cp $BASE/../conf/path_info.json $NGINX_PREFIX
}

set_config() {
  enforce_nginx_prefix

  #cp $NGINX_PREFIX/conf/nginx.conf $NGINX_PREFIX/conf/nginx.conf.orig
  cp -R $NGINX_CONFIG_DIR/conf $NGINX_PREFIX
  sed -e "s@--NGINX_PREFIX--@$NGINX_PREFIX@g" $NGINX_PREFIX/conf/nginx.conf > $NGINX_PREFIX/conf/nginx.conf.tmp
  mv $NGINX_PREFIX/conf/nginx.conf.tmp $NGINX_PREFIX/conf/nginx.conf

}

