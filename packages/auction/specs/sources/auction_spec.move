module specs::auction_spec;

use std::string::String;
use sui::{clock::Clock, coin::Coin};

use suins_auction::{
    auction::{Self, AdminCap, AuctionTable},
    constants::{version, max_percentage, min_bid_increase_percentage, bid_extend_time},
    offer::{Self, OfferTable},
};

#[spec_only]
use prover::prover::{asserts, ensures};
#[spec_only]
use prover::ghost;
#[spec_only]
use specs::transfer_spec::{SpecTransferAddress, SpecTransferAddressExists};

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

#[spec(prove, target = auction::place_bid)]
public fun place_bid_spec<T>(
    auction_table: &mut AuctionTable,
    domain_name: String,
    coin: Coin<T>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    ghost::declare_global_mut<SpecTransferAddress, address>();
    ghost::declare_global_mut<SpecTransferAddressExists, bool>();

    let domain = *domain_name.bytes();
    let now = clock.timestamp_ms() / 1000;
    let bid_amount = coin.value();

    // Version check
    asserts(auction::spec_get_version(auction_table) == version());

    // Domain must exist in bag with correct type
    asserts(auction::spec_auction_exists<T>(auction_table, domain));

    // Time checks
    let start_time = auction::spec_get_start_time<T>(auction_table, domain);
    let end_time = auction::spec_get_end_time<T>(auction_table, domain);
    asserts(now > start_time);
    asserts(now < end_time);

    // Minimum bid check
    let min_bid = auction::spec_get_min_bid<T>(auction_table, domain);
    asserts(bid_amount >= min_bid);

    // Bid increase checks (conditional on existing bid)
    let highest_bid_value = auction::spec_get_highest_bid_value<T>(auction_table, domain);
    if (highest_bid_value > 0) {
        // Overflow: highest_bid_value * min_bid_increase_percentage()
        asserts(
            (highest_bid_value as u128) * (min_bid_increase_percentage() as u128)
                <= (std::u64::max_value!() as u128),
        );
        let min_increase = (highest_bid_value * min_bid_increase_percentage()) / max_percentage();
        // Overflow: highest_bid_value + min_increase
        asserts(
            (highest_bid_value as u128) + (min_increase as u128)
                <= (std::u64::max_value!() as u128),
        );
        let min_required_bid = highest_bid_value + min_increase;
        asserts(bid_amount >= min_required_bid);
    };

    // Time extension overflow check
    if (end_time - now < bid_extend_time()) {
        asserts(
            (now as u128) + (bid_extend_time() as u128)
                <= (std::u64::max_value!() as u128),
        );
    };

    auction::place_bid<T>(auction_table, domain_name, coin, clock, ctx);
}
