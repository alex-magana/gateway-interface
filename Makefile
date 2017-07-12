.PHONY: clean build test release

COMPONENT="ws-alephamp-lambda-message-constructor"

test:
	docker build -t ws-lambda-message-constructor .
	docker run --rm ws-lambda-message-constructor

clean:
	rm -rf src/node_modules package.zip

# NB: We don't need the aws-sdk package in the ZIP we're creating - it's automatically provided by AWS Lambda
# Removing it saves us a couple of MB per deployment!

build:
	sh ./build-tools/mock-run.sh --os 7 \
		--install "npm" \
		--copyin src src \
		--shell 'npm install --prefix src && rm -r src/node_modules/aws-sdk && zip -9 -r package.zip src' \
		--copyout package.zip package.zip

release: clean build
	cosmos-release lambda --lambda-version=${BUILD_NUMBER} "./package.zip" $(COMPONENT)

release_interface:
	docker build -t ws-lambda-message-constructor-api-interface .
	docker run --rm ws-lambda-message-constructor-api-interface
