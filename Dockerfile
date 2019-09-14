FROM i386/debian

WORKDIR /app

RUN apt update && apt install gcc make flex bison nasm git g++ python3 wget mc mcedit -y

# Interactive mode
CMD bash

# Running tests
# CMD make clean && make test