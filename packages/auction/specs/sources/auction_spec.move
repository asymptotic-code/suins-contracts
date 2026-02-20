module specs::auction_spec;

use suins_auction::{
    auction::{Self, AdminCap, AuctionTable},
    constants::{version, max_percentage},
    offer::{Self, OfferTable},
};

#[spec_only]
use prover::prover::{asserts, ensures};

#[spec(prove, target = auction::set_service_fee)]
public fun set_service_fee_spec(
    _: &AdminCap,
    auction_table: &mut AuctionTable,
    offer_table: &mut OfferTable,
    service_fee: u64,
) {
    // Abort conditions
    asserts(auction::spec_get_version(auction_table) == version());
    asserts(offer::spec_get_version(offer_table) == version());
    asserts(service_fee < max_percentage());

    auction::set_service_fee(_, auction_table, offer_table, service_fee);

    // Postconditions
    ensures(auction::spec_get_service_fee(auction_table) == service_fee);
    ensures(offer::spec_get_service_fee(offer_table) == service_fee);
}
