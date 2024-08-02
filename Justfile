build:
    docker buildx build -t rgpeach10/shell:local --load .

run tag="local":
    docker run -it --rm -v $HOME/.ssh:/home/rgpeach10/.ssh -v $(pwd):/home/rgpeach10/mnt rgpeach10/shell:{{tag}}

test:
    just build
    just run local

clean:
    docker image prune -f
    docker container prune -f
    docker system prune -f
    docker volume prune -f
