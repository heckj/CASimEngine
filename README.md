# CASimEngine

An engine to run cellular automata simulations over a collection of voxels.

## Checking things in Linux

(Uses Docker or Orbstack)

Preload the images:

```bash
docker pull swift:5.9    # 2.55GB
docker pull swift:5.10   # 2.57GB
docker pull swift:6.0    # 3.2GB
```

Get a command-line operational with the version of swift you want. For example:

```bash
docker run --rm --privileged --interactive --tty --volume "$(pwd):/src" --workdir "/src" swift:5.10
```

Append on specific scripts or commands for run-and-done:

```bash
docker run --rm --privileged --interactive --tty --volume "$(pwd):/src" --workdir "/src" swift:5.9 ./scripts/docker-test.bash
```

