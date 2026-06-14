# WallstreetProject Makefile

.PHONY: install dev test build clean

# ============ Flutter Client ============
install-client:
	cd client && flutter pub get

run-client-web:
	cd client && flutter run -d chrome

run-client-android:
	cd client && flutter run -d android

run-client-ios:
	cd client && flutter run -d ios

run-client-macos:
	cd client && flutter run -d macos

build-client-web:
	cd client && flutter build web --release

build-client-apk:
	cd client && flutter build apk --release

# ============ Go Server ============
run-go:
	cd server-go && go run cmd/server/main.go

build-go:
	cd server-go && go build -o bin/wallstreet-go cmd/server/main.go

# ============ Python Server ============
install-python:
	cd server-python && pip install -r requirements.txt --break-system-packages

run-python:
	cd server-python && uvicorn app.main:app --reload --port 8000

# ============ Admin ============
install-admin:
	cd admin && npm install

run-admin:
	cd admin && npm run dev

build-admin:
	cd admin && npm run build

# ============ Combined ============
install: install-client install-python install-admin
	cd server-go && go mod tidy

dev:
	@echo "Start in 3 terminals:"
	@echo "  Terminal 1: make run-python"
	@echo "  Terminal 2: make run-go"
	@echo "  Terminal 3: make run-client-web"

test:
	cd server-python && pytest
	cd server-go && go test ./...

build: build-client-web build-go build-admin

clean:
	rm -rf client/build server-go/bin admin/dist
