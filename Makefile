pong: pong.odin
	odin run .

build: pong.odin
	odin build . -o:speed
