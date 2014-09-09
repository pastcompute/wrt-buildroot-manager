#
# When run, this creates a file called $PWD/wrt-buildroot-manager.source that you can source from bashrc
#

DIR=`dirname "$0"`
DIR=`cd "$DIR"; pwd`

cat > wrt-buildroot-manager.source <<EOF
export WRT_BUILDROOT_DIR="$DIR"
export WRT_BUILDROOT_TEMPLATE="$DIR/template"
export PATH="$DIR:\$PATH"
EOF
