use futures::pin_mut;
use rpki::rtr::server::Socket;
use rpki::rtr::state::State;
use std::io;
use std::pin::Pin;
use std::task::{Context, Poll};
use tokio::io::{AsyncRead, AsyncWrite, ReadBuf};
use tokio::net::TcpStream;

/// A wrapper around a stream socket that takes care of updating metrics.
pub struct RtrStream {
    sock: TcpStream,
}

impl RtrStream {
    #[allow(clippy::redundant_async_block)] // False positive
    pub fn new(sock: TcpStream) -> Self {
        RtrStream { sock }
    }
}

impl Socket for RtrStream {
    fn update(&self, state: State, reset: bool) {
        println!("{:?}, {:?}", state.serial(), reset);
    }
}

impl AsyncRead for RtrStream {
    fn poll_read(
        mut self: Pin<&mut Self>,
        cx: &mut Context,
        buf: &mut ReadBuf,
    ) -> Poll<Result<(), io::Error>> {
        let len = buf.filled().len();
        let sock = &mut self.sock;
        pin_mut!(sock);
        let res = sock.poll_read(cx, buf);
        if let Poll::Ready(Ok(())) = res {
            println!("{:?}", (buf.filled().len().saturating_sub(len)) as u64);
        }
        res
    }
}

impl AsyncWrite for RtrStream {
    fn poll_write(
        mut self: Pin<&mut Self>,
        cx: &mut Context,
        buf: &[u8],
    ) -> Poll<Result<usize, io::Error>> {
        let sock = &mut self.sock;
        pin_mut!(sock);
        let res = sock.poll_write(cx, buf);
        if let Poll::Ready(Ok(n)) = res {
            println!("{:?}", n as u64);
        }
        res
    }

    fn poll_flush(mut self: Pin<&mut Self>, cx: &mut Context) -> Poll<Result<(), io::Error>> {
        let sock = &mut self.sock;
        pin_mut!(sock);
        sock.poll_flush(cx)
    }

    fn poll_shutdown(mut self: Pin<&mut Self>, cx: &mut Context) -> Poll<Result<(), io::Error>> {
        let sock = &mut self.sock;
        pin_mut!(sock);
        sock.poll_shutdown(cx)
    }
}
