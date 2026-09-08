FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive LINUXUSBDISPLAY_TEST=1
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential dkms kmod mokutil usbutils openssl shim-signed shellcheck python3 \
    linux-headers-generic linux-headers-generic-hwe-24.04
COPY Linux /opt/Linux
COPY tests /opt/tests
COPY install-ubuntu.sh /opt/install-ubuntu.sh
COPY releases /opt/releases
CMD ["bash", "-c", "python3 /opt/tests/integration.py && python3 /opt/tests/bootstrap.py"]
