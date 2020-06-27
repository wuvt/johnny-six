set("harbor.ssl.certificate", "/etc/harbor/cert.pem")
set("harbor.ssl.private_key", "/etc/harbor/privkey.pem")

script_path = "/usr/src/app"
base_path = getenv("BASE_PATH")
trackman_url = getenv("TRACKMAN_URL")
trackman_password = getenv("TRACKMAN_PASSWORD")
playlist_api_url = getenv("PLAYLIST_API_URL")
