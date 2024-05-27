package pkg_lib;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `define info(MSG, VERBOSITY=UVM_LOW,ID=get_name()) `uvm_info(ID,MSG,VERBOSITY)
    `define sv_rand_check(r) do begin if (!(r)) begin `info("Randomization Failed") $finish; end end while (0)

    typedef enum int {DATA_PROC, SHIFT, PACK} instr_group_t;
    typedef enum int
    {
        /*DATA PROCESS*/ ADC,  ADD,  ADR, AND, BIC, CMP,
        /*SHIFT*/        ASR,  LSL,  LSR,
        /*PACK_UNPACK*/  SXTB, SXTH, UXTB
    } instruction_t;

    class instruction_item extends uvm_object;

        rand instr_group_t instruction_group;
        rand instruction_t instruction;

        instruction_t data_proc_q[$] = {ADC,  ADD,  ADR, AND, BIC, CMP};
        instruction_t shift_q[$]     = {ASR, LSL, LSR};
        instruction_t pack_q[$]      = {SXTB, SXTH, UXTB};

        static int data_proc_cnt;
        static int shift_cnt;
        static int pack_cnt;
        static int total_cnt;

        constraint inster_c {

            // Choose instruction from group
            if (instruction_group==DATA_PROC) {
                instruction inside {data_proc_q};
            }
            else if (instruction_group==SHIFT) {
                instruction inside {shift_q};
            }
            else {
                instruction inside {pack_q};
            }

            // Apply variable ordering
            solve instruction_group before instruction;
        }

        `uvm_object_utils_begin(instruction_item)
            `uvm_field_enum(instr_group_t, instruction_group, UVM_DEFAULT)
            `uvm_field_enum(instruction_t, instruction, UVM_DEFAULT)
        `uvm_object_utils_end

        function new (string name="instruction_item");
            super.new(name);
        endfunction

        function void post_randomize();
            if (instruction inside {data_proc_q}) begin
                data_proc_cnt++;
                total_cnt++;
            end
            else if (instruction inside {shift_q}) begin
                shift_cnt++;
                total_cnt++;
            end
            else begin
                pack_cnt++;
                total_cnt++;
            end
        endfunction : post_randomize

        function string convert2string ();
            return $sformatf("For item: %s, inster_group: %s, instruction: %s",get_name(), instruction_group.name(), instruction.name());
        endfunction

    endclass

    class solve_before_test extends uvm_test;

        rand instruction_item instruction;

        `uvm_component_utils(solve_before_test)

        function new (string name, uvm_component parent);
            super.new(name, parent);
        endfunction

        task run_phase (uvm_phase phase);
            super.run_phase(phase);
            for(int idx=0; idx<1200; idx++) begin
                instruction=instruction_item::type_id::create($sformatf("instruction[%0d]",idx),this);
                `sv_rand_check(instruction.randomize());
            end
        endtask

        function void final_phase (uvm_phase phase);
            string s="\n";
            $sformat(s,"%s\n**********************************************************************************\n",s);
            $sformat(s,"%s Total number of data process instructions: %0d, percent from total: %9.3f\n",s,
                instruction_item::data_proc_cnt, 100 * instruction_item::data_proc_cnt/instruction_item::total_cnt);
            $sformat(s,"%s Total number of shift        instructions: %0d, percent from total: %9.3f\n",s,
                instruction_item::shift_cnt, 100 * instruction_item::shift_cnt/instruction_item::total_cnt);
            $sformat(s,"%s Total number of pack unpack  instructions: %0d, percent from total: %9.3f\n",s,
                instruction_item::pack_cnt, 100 * instruction_item::pack_cnt/instruction_item::total_cnt);
            $sformat(s,"%s***********************************************************************************\n",s);
            `info(s)
        endfunction

    endclass

endpackage

module top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import pkg_lib::*;
    initial run_test("solve_before_test");
endmodule
