build:
    docker buildx build --progress=plain -t rgpeach10/shell:local . --load

run-local:
    docker run -it --rm \
        -v $HOME/.ssh:/home/root/.ssh \
        -v $HOME:/home/root/mnt \
        -w /home/root/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/root/mnt \
        -e DEBUG=1 \
        rgpeach10/shell:local

run-remote tag="local":
    docker run -it --rm \
        -v $HOME/.ssh:/home/root/.ssh \
        -v $HOME:/home/root/mnt \
        -w /home/root/mnt \
        -e GITHUB_TOKEN=$(gh auth token) \
        -e MNT=/home/root/mnt \
        --pull=always \
        rgpeach10/shell:{{tag}}

build-all tag="local":
    docker buildx build --progress=plain -t rgpeach10/shell:{{tag}} --platform linux/amd64,linux/arm64 . --push

test:
    just build
    just run-local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f

push-local: build
    echo $(git symbolic-ref --short HEAD | sed 's/\//__/g')
    docker tag rgpeach10/shell:local rgpeach10/shell:$(git symbolic-ref --short HEAD | sed 's/\//__/g')
    docker push rgpeach10/shell:$(git symbolic-ref --short HEAD | sed 's/\//__/g')

stow: 
    stow -t $HOME -d ./home

stow-hard:
    stow -t $HOME -d ./home --adopt
    git reset --hard