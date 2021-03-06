#!/bin/bash
#set -eux
#===================================================================================================
#
# Build Product
#
#===================================================================================================
#---------------------------------------------------------------------------------------------------
# env
#---------------------------------------------------------------------------------------------------
dir_script="$(dirname $0)"
cd "$(cd ${dir_script}; cd ../..; pwd)" || exit 1

readonly DIR_BASE="$(pwd)"
. "${DIR_BASE}/build/env.properties"

product="in-house-swagger"
version="$(cat ${DIR_SRC}/VERSION)"
archive_name="${product}-${version}"
archive_name_with_dpend="${product}-with-depends-${version}"

#---------------------------------------------------------------------------------------------------
# check
#---------------------------------------------------------------------------------------------------
if [[ "$(which md5sum)x" = "x" ]]; then
  echo "md5sum is not installed." >&2
  exit 1
fi


#---------------------------------------------------------------------------------------------------
# prepare
#---------------------------------------------------------------------------------------------------
echo "init dist directory"
if [[ -d "${DIR_DIST}" ]]; then rm -fr "${DIR_DIST}"; fi
mkdir -p "${DIR_DIST}"


#---------------------------------------------------------------------------------------------------
# analyze
#---------------------------------------------------------------------------------------------------
build/product/analyze.sh
retcode=$?
if [[ ${retcode} -ne 0 ]]; then exit ${retcode}; fi


#---------------------------------------------------------------------------------------------------
# build
#---------------------------------------------------------------------------------------------------
dir_dist_work="${DIR_DIST}/${archive_name_with_dpend}"
mkdir -p "${dir_dist_work}"

echo ""
echo "ソースのコピー"
cp -pr "${DIR_SRC}/"* "${dir_dist_work}/"

echo ""
echo "不要ファイルの削除"
find "${dir_dist_work}" -type f -name ".gitkeep"  | xargs -I{} bash -c 'echo "rm -f {}"; rm -f {}'
find "${dir_dist_work}" -type f -name ".DS_Store" | xargs -I{} bash -c 'echo "rm -f {}"; rm -f {}'


#---------------------------------------------------------------------------------------------------
# test
#---------------------------------------------------------------------------------------------------
echo ""
echo "インストールスクリプトの動作確認"
${dir_dist_work}/bin/install
retcode=$?
if [[ ${retcode} -ne 0 ]]; then
  echo "インストールスクリプトでエラーが発生しました。" >&2
  exit 6
fi

#---------------------------------------------------------------------------------------------------
# package
#---------------------------------------------------------------------------------------------------
echo ""
echo "配布アーカイブに不要なファイルの削除"
rm -fr "${dir_dist_work:?}/config/templates/_default"

echo ""
echo "依存を含めた配布アーカイブの作成"
rm -fr "${dir_dist_work:?}/lib/"
rm -fr "${dir_dist_work:?}/module/"
cd ${DIR_DIST}
tar czf "./${archive_name_with_dpend}.tar.gz" "./${archive_name_with_dpend}"
md5sum  "./${archive_name_with_dpend}.tar.gz" | cut -d ' ' -f 1 > "./${archive_name_with_dpend}.tar.gz.md5"

echo ""
echo "依存を含めない配布アーカイブの作成"
rm -fr "${dir_dist_work:?}/archive/"
mv "./${archive_name_with_dpend}" "./${archive_name}"
tar czf "./${archive_name}.tar.gz" "./${archive_name}"
md5sum  "./${archive_name}.tar.gz" | cut -d ' ' -f 1 > "./${archive_name}.tar.gz.md5"

echo ""
echo "作業ディレクトリの削除"
rm -fr "./${archive_name:?}/"

#---------------------------------------------------------------------------------------------------
# teardown
#---------------------------------------------------------------------------------------------------
echo "results:"
find "${DIR_DIST}" -type f

echo ""
echo "ビルドが完了しました。"
exit 0
