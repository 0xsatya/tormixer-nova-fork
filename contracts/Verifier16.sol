//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );

/*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
    }
    /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
    function negate(G1Point memory p) internal pure returns (G1Point memory r) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
    ) internal view returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier16 {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }
    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            20491192805390485299153009773594534940189261866228447918068658471970481763042,
            9383485363053290200918347156157836566562967994039712273449902621266178545958
        );

        vk.beta2 = Pairing.G2Point(
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [17494747732693439013649116717141210485154234075756151105515248691241413706455,
             20205555897526700189157898980705652607582922661107027175151588376239571956096],
            [7190142417350091893734262701568558876805640009130986706752709463068260639787,
             14259914854386196429102054426458677502272223066447301649494999520296889973314]
        );
        vk.IC = new Pairing.G1Point[](22);
        
        vk.IC[0] = Pairing.G1Point( 
            7662933866985223139865024345648036176497967855526365034670849911591601307940,
            20729444928461046476088347967763232773118435938438498972265767376104110969425
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            21101239085204735800432733382793680653657739215204652713076152722763884844335,
            15037220826171661035319650994250431320812084805487224802022644350165955656006
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            17889727011089929368494588280033829807223550671537866623342302890018030303214,
            1820257913106457479730167987892441565163927212122465063572495355264361716312
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            20526882035484573678476858630771630932200805745166417690315274909728277775217,
            11782291676083890701895171598352857700948756292052942558352655364961141223091
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            2026706995334149133619884143331504410130643787469278050519154333630202591475,
            17725252663136394598050402879309939295804121941713366816936832567147137544549
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            6023872734861866569492072284077813405262771922400840415578140532039909592741,
            2644108534939346518270056208208132778269524145838670699738575246182259363111
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            3860902412560404992663643488628252401757525077869797040465111756305267581936,
            2642890939438514593103639225240585839580452247931359393977796804476659433179
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            7888010327358307075893426780722707996776568012987901390074160886163242095172,
            14131366783863164091372903011397250278421697358597670602177325964444767411182
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            18589023487511454415859040153498458597012334774209077411214307707376167421700,
            3138745893022405137975234810647655017652493448104856157317525463555309462276
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            7410198583073590501560813316755171198662111376886810846056130742798447378178,
            3702222733231089392272440287662667256340036663989485994510950684959504560872
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            11207768658856008433994194395727533407918033567993268578405774280039276653606,
            4747139566479035649266703379337113886824189185301193905235999944142099450827
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            9591707991062522978108331199072600237567003607869476969132687118661856147862,
            20623867747537973585681418158073348376264914715807360762851096403225349443694
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            14138757015758771756506449899683085375838344290543484705779064783606803379154,
            19597173631745152010592632312261161242521626121854299483100275228648651027790
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            15077928004225060792403557704213089289567352651891018613052780691644142745805,
            2369648350627262702957106893756434715760088782452149870494393339916659116301
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            18669034834048986819777552284137424290427550610137599719726390035970681943248,
            4746029344069441589969419487536092957015032381195022099314288688810401850645
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            17380552222842652700914814835023883470832788128278730647192416421450005512881,
            10390313360304091817174099992732386109472425067532869409305530125301738443022
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            4348401883496221773313795003133118366119772433614038329273220171841440369267,
            12083698041039435010806898885271892765226779084177862286564544522193137835243
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            9410500770742227356527680800602566345784720959197829601493464428580286294283,
            20512148232909392258311062113390071569394089171653385026538257595891006834625
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            21252366228227129074627667376976522403212218123137095649242881444035793340041,
            8199640041544819492228273259115294633314081508854890603390759240621869764551
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            11810375366722033950640893395180830210633571506276583614351997854644609071026,
            19537155592357365042901756785286507816515873213765758575325121660918876970467
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            10683138631175874235735628472446273431769062422026072611117067218519524730667,
            9490487632762992078715793917962293267310847151848482835452532196450383128378
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            11309044977594642634997636995874579035209504671965477085511849106911646258834,
            950681706424678907137170488195133992079998720366525530504927310816268636367
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[21] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
