mod rtr;

use rpki::resources::Asn;
use std::error::Error;
use tokio::net::TcpListener;

use rpki::rtr::pdu::{Aspa, CacheResponse, EndOfData, ProviderAsns, ResetQuery};
use rpki::rtr::state::{Serial, State};
use rpki::rtr::Timing;

use rand;
use rand::Rng;

async fn generate_random_aspa_object(flag: u8) -> Aspa {
    let cas = rand::thread_rng().gen_range(1..200);

    let num_pas = rand::thread_rng().gen_range(1..100);
    let mut pas = vec![];

    for i in 0..num_pas {
        pas.push(Asn::from_u32(rand::thread_rng().gen_range(1..200)))
    }

    // constructing aspa pdu
    Aspa::new(
        1,
        flag,
        Asn::from_u32(cas),
        ProviderAsns::try_from_iter(pas.into_iter())
            .expect("cannot generate aspa pdu"),
    )
}

async fn process_socket(stream: &mut rtr::RtrStream) {
    // version id for header
    let version = 1;
    let start_serial = 42;
    let customer_as = Asn::from_u32(32);
    let list_provider_as: Vec<Asn> = vec![3, 4, 5].into_iter().map(Asn::from_u32).collect();

    // reset query request by the rtr client
    let _reset_query = ResetQuery::read(stream)
        .await
        .expect("cannot parse reset query");

    // construct current state with serial
    let mut session_state = State::new_with_serial(Serial::from_be(start_serial));

    // rtr server should respond with cache response pud
    let cache_response = CacheResponse::new(version, session_state);

    // sending cache response
    cache_response
        .write(stream)
        .await
        .expect("cannot write cache response");


    for i in 0..10000 {
        let new_pdu: Aspa = generate_random_aspa_object(rand::thread_rng().gen_range(0..1)).await;

        // send aspa pdu
       new_pdu
            .write(stream)
            .await
            .expect("cannot transmit aspa rtr pdu");
    }


    // increment session serial by one
    session_state.inc();

    // endofdata pdu
    let end_of_data = EndOfData::new(version, session_state, Timing::default());

    // send endofdata
    end_of_data
        .write(stream)
        .await
        .expect("couldn't send end of data pdu");


    // ####################


}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    println!("Starting RTR Server");
    let addr = std::env::var("ADDR").expect("NO ADDR SPECIFIED");
    let listener = TcpListener::bind(addr).await?;

    loop {
        let (socket, _) = listener.accept().await?;
        let mut rtr_stream = rtr::RtrStream::new(socket);
        process_socket(&mut rtr_stream).await;
    }
}
