//
//  MixpanelPeopleTests.swift
//  MixpanelDemo
//
//  Created by Yarden Eitan on 6/28/16.
//  Copyright © 2016 Mixpanel. All rights reserved.
//

import XCTest
import Nocilla

@testable import Mixpanel
@testable import MixpanelDemo

class MixpanelPeopleTests: MixpanelBaseTests {

    func testPeopleSet() {
        mixpanel.identify(distinctId: "d1")
        var p: Properties = ["p1": "a"]
        mixpanel.people.set(properties: p)
        waitForSerialQueue()
        p = mixpanel.peopleQueue.last!["$set"] as! Properties
        XCTAssertEqual(p["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(p)
    }

    func testPeopleSetOnce() {
        mixpanel.identify(distinctId: "d1")
        var p: Properties = ["p1": "a"]
        mixpanel.people.setOnce(properties: p)
        waitForSerialQueue()
        p = mixpanel.peopleQueue.last!["$set_once"] as! Properties
        XCTAssertEqual(p["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(p)
    }

    func testPeopleSetReservedProperty() {
        mixpanel.identify(distinctId: "d1")
        var p: Properties = ["$ios_app_version": "override"]
        mixpanel.people.set(properties: p)
        waitForSerialQueue()
        p = mixpanel.peopleQueue.last!["$set"] as! Properties
        XCTAssertEqual(p["$ios_app_version"] as? String,
                       "override",
                       "reserved property override failed")
        assertDefaultPeopleProperties(p)
    }

    func testPeopleSetTo() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.set(property: "p1", to: "a")
        waitForSerialQueue()
        var p: Properties = mixpanel.peopleQueue.last!["$set"] as! Properties
        XCTAssertEqual(p["p1"] as? String, "a", "custom people property not queued")
        assertDefaultPeopleProperties(p)
    }

    func testDropUnidentifiedPeopleRecords() {
        for i in 0..<505 {
            mixpanel.people.set(property: "i", to: i)
        }
        waitForSerialQueue()
        XCTAssertTrue(mixpanel.people.unidentifiedQueue.count == 500)
        var r: Properties = mixpanel.people.unidentifiedQueue.first!
        XCTAssertEqual(r["$set"]?["i"], 5)
        r = mixpanel.people.unidentifiedQueue.last!
        XCTAssertEqual(r["$set"]?["i"], 504)
    }

    func testDropPeopleRecords() {
        mixpanel.identify(distinctId: "d1")
        for i in 0..<505 {
            mixpanel.people.set(property: "i", to: i)
        }
        waitForSerialQueue()
        XCTAssertTrue(mixpanel.peopleQueue.count == 500)
        var r: Properties = mixpanel.peopleQueue.first!
        XCTAssertEqual(r["$set"]?["i"], 5)
        r = mixpanel.peopleQueue.last!
        XCTAssertEqual(r["$set"]?["i"], 504)
    }

    func testPeopleAssertPropertyTypes() {
        var p: Properties = ["URL": Data()]
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.set(properties: p)
        }
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.set(property: "p1", to: Data())
        }
        p = ["p1": "a"]
        // increment should require a number
        XCTExpectAssert("unsupported property type was allowed") {
            mixpanel.people.increment(properties: p)
        }
    }

    func testPeopleAddPushDeviceToken() {
        mixpanel.identify(distinctId: "d1")
        let token: Data = "0123456789abcdef".data(using: String.Encoding.utf8)!
        mixpanel.people.addPushDeviceToken(token)
        waitForSerialQueue()
        XCTAssertTrue(mixpanel.peopleQueue.count == 1, "people records not queued")
        var p: Properties = mixpanel.peopleQueue.last!["$union"] as! Properties
        XCTAssertTrue(p.count == 1, "incorrect people properties: \(p)")
        let a: [AnyObject] = p["$ios_devices"] as! [AnyObject]
        XCTAssertTrue(a.count == 1, "device token array not set")
        XCTAssertEqual(a.last as? String,
                       "30313233343536373839616263646566",
                       "device token not encoded properly")
    }

    func testPeopleIncrement() {
        mixpanel.identify(distinctId: "d1")
        var p: Properties = ["p1": 3]
        mixpanel.people.increment(properties: p)
        waitForSerialQueue()
        p = mixpanel.peopleQueue.last!["$add"] as! Properties
        XCTAssertTrue(p.count == 1, "incorrect people properties: \(p)")
        XCTAssertEqual(p["p1"] as? Int, 3, "custom people property not queued")
    }

    func testPeopleIncrementBy() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.increment(property: "p1", by: 3)
        waitForSerialQueue()
        var p: Properties = mixpanel.peopleQueue.last!["$add"] as! Properties
        XCTAssertTrue(p.count == 1, "incorrect people properties: \(p)")
        XCTAssertEqual(p["p1"] as? Int, 3, "custom people property not queued")
    }

    func testPeopleDeleteUser() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.deleteUser()
        waitForSerialQueue()
        let p: Properties = mixpanel.peopleQueue.last!["$delete"] as! Properties
        XCTAssertTrue(p.count == 0, "incorrect people properties: \(p)")
    }


    func testPeopleTrackChargeDecimal() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25.34)
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        let prop = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$time"]
        XCTAssertEqual(prop, 25.34)
        XCTAssertNotNil(prop2)
    }

    func testPeopleTrackChargeNil() {
        mixpanel.identify(distinctId: "d1")
        XCTExpectAssert("can't have nil as trackCharge") {
            mixpanel.people.trackCharge(amount: nil)
        }
        XCTAssertTrue(mixpanel.peopleQueue.count == 0)
    }

    func testPeopleTrackChargeZero() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 0)
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        let prop = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$time"]
        XCTAssertEqual(prop, 0)
        XCTAssertNotNil(prop2)
    }
    func testPeopleTrackChargeWithTime() {
        mixpanel.identify(distinctId: "d1")
        var p: Properties = allPropertyTypes()
        mixpanel.people.trackCharge(amount: 25, properties: ["$time": p["date"]!])
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        let prop = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$time"]
        XCTAssertEqual(prop, 25)
        XCTAssertEqual(prop2 as? Date, p["date"] as? Date)
    }

    func testPeopleTrackChargeWithProperties() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25, properties: ["p1": "a"])
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        let prop = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["p1"]
        XCTAssertEqual(prop, 25)
        XCTAssertEqual(prop2 as? String, "a")
    }

    func testPeopleTrackCharge() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.trackCharge(amount: 25)
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        let prop = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$amount"] as? Double
        let prop2 = ((r["$append"] as? Properties)?["$transactions"] as? Properties)?["$time"]
        XCTAssertEqual(prop, 25)
        XCTAssertNotNil(prop2)
    }

    func testPeopleClearCharges() {
        mixpanel.identify(distinctId: "d1")
        mixpanel.people.clearCharges()
        waitForSerialQueue()
        var r: Properties = mixpanel.peopleQueue.last!
        XCTAssertEqual(r["$set"]?["$transactions"], [])
    }
}
