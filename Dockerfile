FROM redis AS builder

ENV DEPS "build-essential git ca-certificates curl unzip"

#install latest cmake
ADD https://cmake.org/files/v3.12/cmake-3.12.4-Linux-x86_64.sh /cmake-3.12.4-Linux-x86_64.sh
RUN mkdir /opt/cmake
RUN sh /cmake-3.12.4-Linux-x86_64.sh --prefix=/opt/cmake --skip-license
RUN ln -s /opt/cmake/bin/cmake /usr/local/bin/cmake
RUN cmake --version

# Set up a build environment
RUN set -ex;\
    deps="$DEPS";\
    apt-get update;\
    apt-get install -y --no-install-recommends $deps;

# Get the dependencies
WORKDIR /redisai
ADD ./ /redisai
#ADD get_deps.sh .
#ADD ./test /redisai/test
RUN bash ./get_deps.sh cpu

# Build the source
#ADD ./src /redisai/src
#ADD Makefile .
RUN make && make install

# Package the runner
FROM redis
ENV LD_LIBRARY_PATH /usr/lib/redis/modules

RUN set -ex;\
    mkdir -p "$LD_LIBRARY_PATH";

COPY --from=builder /redisai/install/redisai.so "$LD_LIBRARY_PATH"
COPY --from=builder /redisai/install/libtensorflow.so "$LD_LIBRARY_PATH"
COPY --from=builder /redisai/install/libtensorflow_framework.so "$LD_LIBRARY_PATH"

WORKDIR /data
EXPOSE 6379
CMD ["--loadmodule", "/usr/lib/redis/modules/redisai.so"]
