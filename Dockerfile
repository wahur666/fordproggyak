FROM i386/debian:8

WORKDIR /app

RUN apt update && apt install gcc make flex bison bisonc++ nasm git g++ python3 wget mc mcedit -y

# Interactive mode
CMD bash

# Running tests
# CMD make clean && make test