## Clone gerrit

```bash
git clone --recurse-submodules https://gerrit.googlesource.com/gerrit -b v2.13.9
```

## Install jdk

```bash
curl -LO https://mirrors.huaweicloud.com/java/jdk/8u202-b08/jdk-8u202-linux-x64.tar.gz
sudo tar -zxvfjdk-8u202-linux-x64.tar.gz -C /opt/

export JAVA_HOME=/opt/jdk1.8.0_202/
export PATH=/opt/jdk1.8.0_202/bin:$PATH
```

## Build buck

```bash
git clone https://github.com/facebook/buck
cd buck
git checkout $(cat ../gerrit/.buckversion)
ant
```

## Build lfs

```bash
cd gerrit
git clone https://gerrit.googlesource.com/plugins/lfs -b stable-2.13 plugins/lfs
touch .nobuckcheck
buck build plugins/lfs
```

## Reference

-[dev-buck](https://gerrit-documentation.storage.googleapis.com/Documentation/2.13/dev-buck.html)

- [lfs-build](https://gerrit.googlesource.com/plugins/lfs/+/refs/heads/stable-2.13/src/main/resources/Documentation/build.md)
