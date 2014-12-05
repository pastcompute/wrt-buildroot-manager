# Apply OpenWRT patches on stock kernel

OWRT_SOURCES=/scratch/develop/wbm-c3/openwrt
TAG=v3.14.25

set -e
set -x

#git branch -f checkout_$TAG $TAG
#git checkout checkout_$TAG
git branch -f owrt_only_$TAG
git checkout owrt_only_$TAG


X=${OWRT_SOURCES}/target/linux/generic/files
cp -av $X/* .

X=${OWRT_SOURCES}/target/linux/ar71xx/files
cp -av $X/* .

X=${OWRT_SOURCES}/target/linux/generic/patches-3.14
for x in `cd $X ; ls |sort` ; do
  echo "PATCH: [$X/$x]"
  patch -f -p1 -E -d. < $X/$x || { bash; true; }
  git add -A ; git commit -m "$x"
done

X=${OWRT_SOURCES}/target/linux/ar71xx/patches-3.14
for x in `cd $X ; ls |sort` ; do
  echo "PATCH: [$X/$x]"
  patch -l -f -p1 -E -d. < $X/$x || { bash; true; }
  git add -A ; git commit -m "$x"
done

