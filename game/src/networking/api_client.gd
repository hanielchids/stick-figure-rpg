## HTTP client for communicating with the Rails backend API.
## Access via the ApiClient autoload singleton.
extends Node

const DEFAULT_URL: String = "http://localhost:3000/api/v1"

var base_url: String = DEFAULT_URL
var auth_token: String = ""
var current_user: Dictionary = {}
var is_logged_in: bool = false

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)


func signup(username: String, email: String, password: String, callback: Callable) -> void:
	var body: String = JSON.stringify({
		"username": username,
		"email": email,
		"password": password
	})
	_http_post("/auth/signup", body, callback)


func login(email: String, password: String, callback: Callable) -> void:
	var body: String = JSON.stringify({
		"email": email,
		"password": password
	})
	_http_post("/auth/login", body, callback)


func get_profile(callback: Callable) -> void:
	_http_get("/profile", callback)


func update_loadout(preferred_weapon: String, skin_id: String, callback: Callable) -> void:
	var body: String = JSON.stringify({
		"preferred_weapon": preferred_weapon,
		"skin_id": skin_id
	})
	_http_put("/profile/loadout", body, callback)


func get_player_stats(player_id: int, callback: Callable) -> void:
	_http_get("/players/%d/stats" % player_id, callback)


func submit_match_results(match_data: Dictionary, callback: Callable) -> void:
	var body: String = JSON.stringify(match_data)
	_http_post("/matches", body, callback)


func get_leaderboard(scope: String, page: int, callback: Callable) -> void:
	_http_get("/leaderboard?scope=%s&page=%d" % [scope, page], callback)


func set_auth_token(token: String) -> void:
	auth_token = token
	is_logged_in = true


func logout() -> void:
	auth_token = ""
	current_user = {}
	is_logged_in = false


# --- HTTP helpers ---

func _http_get(endpoint: String, callback: Callable) -> void:
	var url: String = base_url + endpoint
	var headers: PackedStringArray = _build_headers()

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
		var response: Dictionary = _parse_response(result, code, body)
		callback.call(response)
		http.queue_free()
	)
	http.request(url, headers, HTTPClient.METHOD_GET)


func _http_post(endpoint: String, body: String, callback: Callable) -> void:
	var url: String = base_url + endpoint
	var headers: PackedStringArray = _build_headers()

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body_bytes: PackedByteArray) -> void:
		var response: Dictionary = _parse_response(result, code, body_bytes)
		callback.call(response)
		http.queue_free()
	)
	http.request(url, headers, HTTPClient.METHOD_POST, body)


func _http_put(endpoint: String, body: String, callback: Callable) -> void:
	var url: String = base_url + endpoint
	var headers: PackedStringArray = _build_headers()

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, body_bytes: PackedByteArray) -> void:
		var response: Dictionary = _parse_response(result, code, body_bytes)
		callback.call(response)
		http.queue_free()
	)
	http.request(url, headers, HTTPClient.METHOD_PUT, body)


func _build_headers() -> PackedStringArray:
	var headers := PackedStringArray(["Content-Type: application/json"])
	if auth_token != "":
		headers.append("Authorization: Bearer " + auth_token)
	return headers


func _parse_response(result: int, code: int, body: PackedByteArray) -> Dictionary:
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "error": "Connection failed", "code": 0}

	var body_text: String = body.get_string_from_utf8()
	var json := JSON.new()
	var parse_result: int = json.parse(body_text)

	if parse_result != OK:
		return {"ok": false, "error": "Invalid response", "code": code}

	var data: Dictionary = {}
	if json.data is Dictionary:
		data = json.data
	data["ok"] = code >= 200 and code < 300
	data["code"] = code
	return data
