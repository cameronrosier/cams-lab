ROOT_DIR="clusters/home"

flux bootstrap github \
  --owner=cameronrosier \
  --repository=cams-lab \
  --branch=main \
  --path=$ROOT_DIR
