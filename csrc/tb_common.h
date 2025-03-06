/*
 * @Author: Zeng GuangYi tgy_scut2021@outlook.com
 * @Date: 2025-01-15 20:31:21
 * @LastEditors: Zeng GuangYi tgy_scut2021@outlook.com
 * @LastEditTime: 2025-01-20 02:51:23
 * @FilePath: /npc/csrc/tb_common.h
 * @Description: Common Verilator testbench headder
 * 
 * Copyright (c) 2025 by ${git_name_email}, All Rights Reserved. 
 */

#ifndef __TB_COM__ // dependency defender
#define __TB_COM__

#define NDEBUG

#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include <typeinfo>
#include <string>
#include <random>
#include <assert.h>

#define __TB__ tb
#define __DUT__ dut

#ifndef __TB__
#error ERROR: NO __TB__ DEFINITION.
#endif

#define TB(a) __TB__->a
#define DUT(a) __DUT__->a


// Check if has rst signal
template<class, class U = void>
struct has_rst : std::false_type { };

template<class T>
struct has_rst<T, std::__void_t<decltype(T::rst)>> : std::true_type { };


// Check if has clk port
template<class, class U = void>
struct has_clk : std::false_type { };

template<class T>
struct has_clk<T, std::__void_t<decltype(T::clk)>> : std::true_type { };



template<class MODULE>
class TESTBENCH_BASE {
public:  
    MODULE *__DUT__;
    VerilatedContext *contextp;
    VerilatedVcdC *m_trace;

    /**
     * @description: Constructor:
     *                  1. specify module type (seq or com).
     *                  2. instantiate __DUT__ contextp m_trace
     *                     with default value.
     *                  3. set trace and trace file name.
     * @param {int}         argc to Get initial value.
     * @param {char}       *argv to Get initial value.
     * @param {Module_type} module_type sepcify simulation type.
     *                      (sequential or combinational?)
     * @return {*}
     */
    TESTBENCH_BASE(int argc, char *argv[]) {
        std::cout << "start constructiog" << std::endl;
        contextp = new VerilatedContext;
        contextp->traceEverOn(true);
        contextp->commandArgs(argc, argv);
        __DUT__ = new MODULE;
        m_trace = new VerilatedVcdC;

        __DUT__->trace(m_trace, 99);
        std::string module_name = typeid(MODULE).name();
        std::cout << module_name << std::endl;
        module_name += ".vcd";
        std::cout << "traceEverOn" << std::endl;
        m_trace->open(module_name.c_str());
        std::cout << "Open Wave File " << module_name << std::endl;
    }

    /**
     * @description: Destructor
     * @return {*}
     */
    ~TESTBENCH_BASE(void) {
        std::cout << "sim finished." << std::endl;
        m_trace->close();
        delete m_trace;
        delete __DUT__;
        delete contextp;
    }

    /**
     * @description: Generate 64-bit random num.
     * @return {*}
     */
    uint64_t rand64() {
        std::random_device rd;
        uint32_t seed = rd();
        std::mt19937_64 rng(seed);
        return rng();
    }

    /**
     * @description: Check if a and b were equal,
     *               if so, PASS this check point,
     *               if not, assert will happed.
     * @param {uint64_t} a number no.1
     * @param {uint64_t} b number no.2
     * @return {*}
     */
    void inline check_eq(uint64_t a, uint64_t b) {
        if (a != b) {
            m_trace->close();
            delete m_trace;
            delete __DUT__;
            delete contextp;
            std::cout << "Assertion at time="
            << contextp->time() << std::endl;
            assert(0);
        } else {
            std::cout << "Check point PASS at time="
            << contextp->time() << std::endl;
        }
    }

    /**
     * @description: sim 1 combinational step
     * @param {function<void()>} codeBlock codeClock that you want
     *                           to exec before setp_comb.
     * @return {*}
     */
    void inline step_comb(std::function<void()> codeBlock) {
        codeBlock();
        this->__DUT__->eval();
        this->contextp->timeInc(1);
        this->m_trace->dump(this->contextp->time());
    }

    void inline init_comb(std::function<void()> codeBlock) {
        this->__DUT__->eval();
        codeBlock();
        this->m_trace->dump(this->contextp->time());
    }
};

template<class MODULE>
class TESTBENCH_CLK : public TESTBENCH_BASE<MODULE> {
public:
    TESTBENCH_CLK(int argc, char *argv[]) :
        TESTBENCH_BASE<MODULE>(argc, argv) { }

    /**
     * @description: Init sim core, dump at time 0.
     *               Important: Must called before any simulation!
     * @param {function<void()>} codeBlock that you want to exec.
     * @return {*}
     */
    void inline init_core(std::function<void()> codeBlock) {
        codeBlock();
        this->init_comb([&](){ this->__DUT__->clk = 1; });
    }

    /**
     * @description: Verify clk and set clk to value i.
     * @param {CData} i Value passed to clk.
     * @return {*}
     */
    void inline set_clk(CData i) {
        this->__DUT__->clk = i;
    }

    /**
     * @description: Verify clk and toggle clk.
     * @return {*}
     */
    void inline toggle_clk() {
        set_clk(!this->__DUT__->clk);
    }

    /**
     * @description: sim 1 step.
     * @param {function<void()>} codeBlock that you want to exec.
     * @return {*}
     */
    void inline single_step_seq(std::function<void()> codeBlock) {
        this->step_comb([&](){
            toggle_clk();
            this->__DUT__->eval();
            codeBlock();
        });
    }

    /**
     * @description: sim 1 un-empty cycle (2 steps per cycle).
     * @param {function<void()>} codeBlock that you want to exec.
     * @return {*}
     */
    void inline cycles(std::function<void()> codeBlock) {
        this->step_comb([this](){ this->toggle_clk(); });
        single_step_seq([&](){ codeBlock(); });
    }

    /**
     * @description: sim i empty cycles (2 steps per cycle).
     * @param {int} i # of cycles to sim.
     * @return {*}
     */
    void inline cycles(int i) {
        for (int j=0; j<i*2; j++) {
            single_step_seq([](){});
        }
    }
};


// main template of TESTBENCH_TYPE
template<class MODULE, bool rst_true, bool clk_true>
class TESTBENCH_TYPE : public TESTBENCH_CLK<MODULE> {
public:
    TESTBENCH_TYPE(int argc, char *argv[])
    : TESTBENCH_CLK<MODULE>(argc, argv){}
};

// sequential logic without rst & with clk
template<class MODULE>
class TESTBENCH_TYPE<MODULE, false, true> : public TESTBENCH_CLK<MODULE> {
public:
    TESTBENCH_TYPE(int argc, char *argv[])
    : TESTBENCH_CLK<MODULE>(argc, argv){}

    /**
     * @description: Init sim, must called before any sim
     *               to make sure waveform at time=0 was
     *               dumped.
     * @return {*}
     */
    void inline sim_init() {
        this->init_core([](){ });
    }
};


// sequential logic with rst & with clk
template<class MODULE>
class TESTBENCH_TYPE<MODULE, true, true> : public TESTBENCH_CLK<MODULE> {
public:
    TESTBENCH_TYPE(int argc, char *argv[])
    : TESTBENCH_CLK<MODULE>(argc, argv){}

    /**
     * @description: Init sim, must called before any sim
     *               to make sure waveform at time=0 was
     *               dumped.
     * @return {*}
     */
    void inline sim_init() {
        this->init_core([this](){ this->__DUT__->rst = 0; });
    }

    /**
     * @description: reset sim by setting dut->rst to 1
     *               (important: dut must contain rst port!)
     *               Cost 1 sim cycle.
     * @return {*}
     */
    void inline sim_reset() {
        this->cycles([this](){ this->__DUT__->rst = 1; });
        this->cycles([this](){ this->__DUT__->rst = 0; });
    }
};

template<class MODULE>
class TESTBENCH : public TESTBENCH_TYPE<MODULE, has_rst<MODULE>::value, has_clk<MODULE>::value> {
public:
    TESTBENCH(int argc, char *argv[])
    : TESTBENCH_TYPE<MODULE, has_rst<MODULE>::value, has_clk<MODULE>::value>(argc, argv){};
};


#endif