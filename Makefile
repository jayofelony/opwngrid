VERSION := $(shell sed -n 's/Version[[:space:]]*=[[:space:]]*"\([0-9.]\+\)"/\1/p' version/ver.go)

all: clean
	@mkdir build
	@go build -o build/pwngrid cmd/pwngrid/*.go
	@ls -la build/pwngrid

install:
	@cp build/pwngrid /usr/local/bin/
	@mkdir -p /etc/systemd/system/
	@mkdir -p /etc/pwngrid/
	@cp env.example /etc/pwngrid/pwngrid.conf
	@systemctl daemon-reload

clean:
	@rm -rf build

restart:
	@service pwngrid restart

release_files: clean cross_compile_libpcap_x64 cross_compile_libpcap_arm
	@mkdir build
	@echo building for linux/amd64 ...
	@CGO_ENABLED=1 CC=x86_64-linux-gnu-gcc GOARCH=amd64 GOOS=linux go build -o build/pwngrid cmd/pwngrid/*.go
	@openssl dgst -sha256 "build/pwngrid" > "build/pwngrid-amd64.sha256"
	@zip -j "build/pwngrid-$(VERSION)-amd64.zip" build/pwngrid build/pwngrid-amd64.sha256 > /dev/null
	@rm -rf build/pwngrid build/pwngrid-amd64.sha256
	@echo building for linux/armhf ...
	@CGO_ENABLED=1 CC=arm-linux-gnueabihf-gcc GOARM=6 GOARCH=arm GOOS=linux go build -o build/pwngrid cmd/pwngrid/*.go
	@openssl dgst -sha256 "build/pwngrid" > "build/pwngrid-armhf.sha256"
	@zip -j "build/pwngrid-$(VERSION)-armhf.zip" build/pwngrid build/pwngrid-armhf.sha256 > /dev/null
	@rm -rf build/pwngrid build/pwngrid-armhf.sha256
	@echo building for linux/aarch64 ...
	@CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc GOARCH=arm64 GOOS=linux go build -o build/pwngrid cmd/pwngrid/*.go
	@openssl dgst -sha256 "build/pwngrid" > "build/pwngrid-aarch64.sha256"
	@zip -j "build/pwngrid-$(VERSION)-aarch64.zip" build/pwngrid build/pwngrid-aarch64.sha256 > /dev/null
	@rm -rf build/pwngrid build/pwngrid-aarch64.sha256
	@ls -la build

# requires sudo apt-get install bison flex gcc-arm-linux-gnueabihf
cross_compile_libpcap_arm:
	@echo "Cross-compiling libpcap for armhf..."
	@wget https://www.tcpdump.org/release/libpcap-1.9.1.tar.gz
	@tar -zxvf libpcap-1.9.1.tar.gz
	@cd libpcap-1.9.1 && \
		export CC=arm-linux-gnueabihf-gcc && \
		./configure --host=arm-linux-gnueabihf && \
		make
	@echo "Copying cross-compiled libpcap to /usr/lib/arm-linux-gnueabihf/"
	@sudo cp libpcap-1.9.1/libpcap.a /usr/lib/arm-linux-gnueabihf/
	@echo "Clean up..."
	@rm -rf libpcap-1.9.1 libpcap-1.9.1.tar.gz

# requires sudo apt-get install bison flex gcc-x86-64-linux-gnu
cross_compile_libpcap_x64:
	@echo "Cross-compiling libpcap for armhf..."
	@wget https://www.tcpdump.org/release/libpcap-1.9.1.tar.gz
	@tar -zxvf libpcap-1.9.1.tar.gz
	@cd libpcap-1.9.1 && \
		export CC=x86_64-linux-gnu-gcc && \
		./configure --host=x86_64-linux-gnu && \
		make
	@echo "Copying cross-compiled libpcap to /usr/lib/aarch64-linux-gnu/"
	@sudo cp libpcap-1.9.1/libpcap.a /usr/lib/x86_64-linux-gnu/
	@echo "Clean up..."
	@rm -rf libpcap-1.9.1 libpcap-1.9.1.tar.gz

.PHONY: cross_compile_libpcap_arm cross_compile_libpcap_aarch64