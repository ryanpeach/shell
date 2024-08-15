# Stage 1: Build environment to install emerge and perform updates
FROM gentoo/stage3:latest as builder

# Update the environment and install necessary tools
RUN emerge --sync && \
    emerge --update --deep --newuse @world && \
    emerge sys-apps/portage

RUN emerge app-eselect/eselect-repository
RUN emerge app-portage/eix

# ======= Sorted ========
RUN emerge dev-vcs/git
RUN emerge app-editors/nano
# ======= END: Sorted =========

# ======= To Sort =========
RUN emerge app-editors/neovim
RUN emerge app-shells/zsh
RUN emerge app-misc/tmux
RUN emerge app-misc/neofetch
# ======= END: To Sort =========

# Clean up unnecessary files and dependencies
RUN emerge --depclean && \
    eclean-dist --deep && \
    eclean-pkg --deep

# Stage 2: Final minimal image
FROM gentoo/stage3:latest

# Copy the updated system from the builder stage
COPY --from=builder / /

# Set up environment variables and entry point
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

CMD ["/bin/zsh"]