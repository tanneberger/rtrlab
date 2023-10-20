mod rtr;

use rpki::resources::Asn;
use std::error::Error;
use tokio::net::TcpListener;

use rpki::rtr::pdu::{Aspa, CacheResponse, EndOfData, ProviderAsns, ResetQuery};
use rpki::rtr::state::{Serial, State};
use rpki::rtr::Timing;

async fn process_socket(stream: &mut rtr::RtrStream) {
    let _reset_query = ResetQuery::read(stream).await.expect("cannot parse reset query");
    let mut session_state = State::new_with_serial(Serial::from_be(42));
    let cache_response = CacheResponse::new(1, session_state);
    cache_response
        .write(stream)
        .await
        .expect("cannot write cache response");
    let aspa_pdu = Aspa::new(
        2,
        0,
        Asn::from_u32(32),
        ProviderAsns::try_from_iter(
            vec![Asn::from_u32(3), Asn::from_u32(4), Asn::from_u32(5)].into_iter(),
        )
        .expect("cannot generate aspa pdu"),
    );
    aspa_pdu.write(stream).await.expect("cannot transmit aspa rtr pdu");

    session_state.inc();
    let end_of_data = EndOfData::new(1, session_state, Timing::default());
    end_of_data
        .write(stream)
        .await
        .expect("TODO: panic message");
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    println!("Starting RTR Server");
    let addr= std::env::var("ADDR").expect("NO ADDR SPECIFIED");
    let listener = TcpListener::bind(addr).await?;

    loop {
        let (socket, _) = listener.accept().await?;
        let mut rtr_stream = rtr::RtrStream::new(socket);
        process_socket(&mut rtr_stream).await;
    }
}
