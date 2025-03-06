#include "tb_common.h"
#include <Vtop.h>//user set

TESTBENCH<Vtop> *__TB__;


int main(int argc, char *argv[]) {
    __TB__ = new TESTBENCH<Vtop>(argc, argv);
    TB(sim_init());
    TB(sim_reset());
    TB(cycles(5));
    TB(~TESTBENCH());
    exit(EXIT_SUCCESS);
}
