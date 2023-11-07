mod rtr;

use rpki::resources::Asn;
use std::error::Error;
use tokio::net::TcpListener;

use rpki::rtr::pdu::{
    Aspa, CacheResponse, EndOfData, ProviderAsns, ResetQuery, SerialNotify, SerialQuery,
};
use rpki::rtr::state::{Serial, State};
use rpki::rtr::Timing;

use rand;
use rand::Rng;
use serde::Deserialize;

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
        ProviderAsns::try_from_iter(pas.into_iter()).expect("cannot generate aspa pdu"),
    )
}

#[derive(Deserialize)]
pub struct Topology {
    as_nummers: Vec<u32>,
    aspas: Vec<(u32, Vec<u32>)>,
}

async fn send_open(stream: &mut rtr::RtrStream, session_state: &mut State) {
    // reset query request by the rtr client
    let _reset_query = ResetQuery::read(stream)
        .await
        .expect("cannot parse reset query");

    // rtr server should respond with cache response pud
    let cache_response = CacheResponse::new(1, *session_state);

    // sending cache response
    cache_response
        .write(stream)
        .await
        .expect("cannot write cache response");
}

async fn announce_config(stream: &mut rtr::RtrStream, x: &mut State) {
    let topology: Topology = serde_json::from_str(
        std::fs::read_to_string(std::env::var("TOPOLOGY_PATH").expect("cannot find TOPOLOGY_PATH"))
            .expect("cannot read topology")
            .as_str(),
    )
    .expect("cannot parse topology");

    // version id for header
    let version = 1;
    let start_serial = 42;
    // construct current state with serial
    let mut session_state = State::new_with_serial(Serial::from_be(start_serial));

    send_open(stream, &mut session_state).await;

    for aspa in topology.aspas {
        let aspa_object = Aspa::new(
            1,
            1, //add //add //add //add
            Asn::from_u32(aspa.0),
            ProviderAsns::try_from_iter(
                aspa.1.into_iter().map(Asn::from_u32).collect::<Vec<Asn>>().into_iter(),
            )
            .expect("cannot generate aspa pdu"),
        );

        aspa_object.write(stream).await.expect("cannot send data");
    }

    // endofdata pdu
    let end_of_data = EndOfData::new(version, session_state, Timing::default());

    // send endofdata
    end_of_data
        .write(stream)
        .await
        .expect("couldn't send end of data pdu");
}

async fn process_socket(stream: &mut rtr::RtrStream) {
    // version id for header
    let version = 1;
    let start_serial = 42;
    // construct current state with serial
    let mut session_state = State::new_with_serial(Serial::from_be(start_serial));

    send_open(stream, &mut session_state).await;

    /*for i in 0..10000 {
        let new_pdu: Aspa = generate_random_aspa_object(1).await;

        // send aspa pdu
        new_pdu
            .write(stream)
            .await
            .expect("cannot transmit aspa rtr pdu");

        if rand::thread_rng().gen_range(0..10) < 3 {
            // constructing aspa pdu
            let wd_pdu: Aspa = Aspa::new(
                1,
                0, // withdraw
                new_pdu.customer(),
                ProviderAsns::empty(),
            );

            wd_pdu
                .write(stream)
                .await
                .expect("cannot transmit withdrawal aspa rtr pdu");
        } else {
            announced_cas.push(new_pdu.customer());
        }
    }*/

    announce_config(stream, &mut session_state).await;

    // increment session serial by one
    session_state.inc();

    // endofdata pdu
    let end_of_data = EndOfData::new(version, session_state, Timing::default());

    // send endofdata
    end_of_data
        .write(stream)
        .await
        .expect("couldn't send end of data pdu");
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
