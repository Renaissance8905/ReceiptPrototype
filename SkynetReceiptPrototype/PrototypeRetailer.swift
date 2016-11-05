//
//  PrototypeRetailer.swift
//  SkynetReceiptPrototype
//
//  Created by Chris Spradling on 11/4/16.
//  Copyright © 2016 LOBC. All rights reserved.
//

import Foundation

/*
 Raw data used for initialization; mimics data retrieved from server during normal startup
*/


let fauxRetailerData: NSDictionary =
[
    "status":"OK",
    "rtelist": [
        "3099": [
            "successor":"3102",
            "predecessor":"0",
            "id":"3099",
            "name":"Top Golf",
            "tabc":"MB835606",
            "region":"N",
            "route":"2.3",
            "payment":"FINT",
            "target_route":"2.3",
            "brandDataArray": [
                "HW15": [
                    "brand":"HW",
                    "size":"15",
                    "quantity":"1",
                    "retailer":"3099"
                ],
                "PZ7": [
                    "brand":"PZ",
                    "size":"7",
                    "quantity":"5",
                    "retailer":"3099"
                ]
            ]
        ],
        "3102": [
            "successor":"0",
            "predecessor":"3099",
            "id":"3102",
            "name":"Opal Divines - Marina",
            "tabc":"MB650377",
            "region":"N",
            "route":"2.3",
            "payment":"COD",
            "target_route":"2.3",
            "brandDataArray": [
                "LA15": [
                    "brand":"LA",
                    "size":"15",
                    "quantity":"3",
                    "retailer":"3102"
                ],
                "PZ7": [
                    "brand":"PZ",
                    "size":"7",
                    "quantity":"3",
                    "retailer":"3102"
                ],
                "BB7": [
                    "brand":"BB",
                    "size":"7",
                    "quantity":"2",
                    "retailer":"3099"
                ]
                
            ]
        ]
    ],
    "miscitems": [
        [
            "descr":"Hat",
            "id":"1",
            "price":"15.00"
        ],
        [
            "descr":"Pint Glass",
            "id":"2",
            "price":"2.50"
        ]
    ],
    "brands": [
        "BB": [
            "instock":"1",
            "name":"Big Bark",
            "price": [
                15: "145.00",
                7: "80.00"
            ]
        ],
        "HW": [
            "instock":"1",
            "name":"Hefeweizen",
            "price": [
                15: "145.00",
                7: "80.00"
            ]
        ],
        "PZ": [
            "instock":"1",
            "name":"Pilz",
            "price": [
                15: "145.00",
                7: "80.00"
            ]
        ],
        "LA": [
            "instock":"1",
            "name":"Liberation",
            "price": [
                15: "155.00",
                7: "85.00"
            ]
        ]
    ],
    "sizes": [
        "15": [
            "name":"Half",
            "short":""
        ],
        "7": [
            "name":"Quarter",
            "short":".25"
        ]
    ],
    "payments": ["COD", "FINT", "PP", "I-Control"],
    "invoice": [16000062, 16000063, 16000064, 16000065, 16000066],
    "route":"2.3",
    "driver": [
        "active":"0",
        "assigned":"2.3",
        "id":"7777",
        "name":"Chris Spradling",
        "selectedroute":"2.3",
        "username":"cspan"
    ]
]
