#pragma once
#include "pch_mm.h"
#include "working_mm.h"

extern front::Schedule         sch;

namespace front {

    void  CriticalHole::start() {

        InitializeConditionVariable(&mole);
        InitializeCriticalSectionAndSpinCount(&whack, 8000);
        escape = false;
        on = true;
    };
    void  CriticalHole::stop() {
        if (on) {
            DeleteCriticalSection(&whack); on = false;
        }
    };

    bool  CriticalHole::next() {
        ///InterlockedDecrement((LONG*)&numMole);
        LeaveCriticalSection(&whack);
        return true;
    };

    void  CriticalHole::EnsureEscapeEnd() {

        if (on) {
            EnterCriticalSection(&whack);
            escape = true;
         
            LeaveCriticalSection(&whack);

            WakeAllConditionVariable(&mole);

        }
    };
    void  CriticalHole::Whack(bool all) {
        if (all)WakeAllConditionVariable(&mole);
        else WakeConditionVariable(&mole);
    };


    void Schedule::start() {
        InitializeCriticalSectionAndSpinCount(&gCs, 8000);
        mask = { 0,{0},nullptr }; ///memset(mask.fmly32, 0, 4 * 64);
        gene = { 0,{0},nullptr }; ///memset(gene.fmly32, 0, 4 * 64);
    };
    void Schedule::stop() {
        DeleteCriticalSection(&gCs);
        if (gene.fmlyNext != nullptr) delete[] gene.fmlyNext;
        mask = { 0,{0},nullptr };
        gene = { 0,{0},nullptr };

    };

    Schedule::tpOrd Schedule::wakeup(bool boss) {

        static tpCnt member = -1;
        constexpr  tpCnt  giant64 = 64 - 1;
        constexpr  tpCnt  giant64x32 = 64 * 32 - 1;
        constexpr  tpCnt  giant64x32x32 = 64 * 32 * 32 - 1;

        if (boss) {

            uint64_t id = _InterlockedCompareExchange(&mask.fmly64, 0, gene.fmly64);
            if (id == gene.fmly64) {
                member = -1;
                gene.fmly64 = 0;
                escape = false;
            }
            else {
                log_bad("a busy mainstream.\n");
            }

            return 0;
        }
        else {


            tpOrd  ID = 0;
            tpCnt order = (tpCnt)(InterlockedIncrement16((SHORT*)&member));

            if (order > giant64) {
                order -= 64;
                if (order > giant64x32) {
                    log_bad("memory out\n");
                }
                else {

                    if (gene.fmly32 == nullptr) {
                        EnterCriticalSection(&gCs);
                        ///gene.fmly32 = new uint32_t[64 * 32];
                        LeaveCriticalSection(&gCs);
                    }

                    ID = (order / 32);
                    ID |= ((order % 32) << 6);

                    InterlockedBitTestAndSet((volatile LONG*)(&mask.fmly32[(order / 32)]), (LONG)(order % 32));
                }
            }
            else {

                InterlockedBitTestAndSet64((LONG64*)&mask.fmly64, (LONG64)order);
                ID = order;

            }
            return ID;
        }
    };
    void Schedule::gohome(tpOrd  order) {
        InterlockedBitTestAndSet64((LONG64*)&gene.fmly64, (LONG64)order);
    };
    bool Schedule::rollcall(uint64_t num) {

        escape = true; escapeID = num;
        while (num != _InterlockedCompareExchange(&gene.fmly64, mask.fmly64, num)) {

 
            std::this_thread::sleep_for(std::chrono::nanoseconds(100));

        };
        escape = false;

        /// assert(room[curry.key].table[curry.buc].val == room[curry.key].table[curry.buc].key);

 
        return true;
    };
    void Schedule::EnsureEscapeEnd() {

        if (escape) {
            EnterCriticalSection(&gCs);
            gene.fmly64 = escapeID;
 
            LeaveCriticalSection(&gCs);
            escape = false;
        }
        else {
 
        };
    };

    Schedule::tpOrd Schedule::wakeup(tpCnt kumi, bool tyo) {

        static tpCnt member[64] = { 0 };
        constexpr  tpCnt  giant64 = 64 - 1;
        constexpr  tpCnt  giant64x32 = 64 * 32 - 1;
        constexpr  tpCnt  giant64x32x32 = 64 * 32 * 32 - 1;

        if (tyo) {

            uint64_t id = _InterlockedCompareExchange(&mask.fmly32[kumi], 0, gene.fmly32[kumi]);
            if (id == gene.fmly32[kumi]) {
                member[kumi] = -1;
                gene.fmly32[kumi] = 0;
            }
            else {
                log_bad("a busy mainstream.\n");
            }

            return 0;
        }



    
        tpCnt order = (tpCnt)(InterlockedIncrement16((SHORT*)&member[kumi])) % 32;

        InterlockedBitTestAndSet((volatile LONG*)(&mask.fmly32[kumi]), (LONG)(order));

        return order;

    };
    void Schedule::gohome(tpCnt kumi, tpCnt sima) {
        InterlockedBitTestAndSet((LONG*)&gene.fmly32[kumi], sima);
    };
    bool Schedule::rollcall(tpCnt kumi, uint32_t num) {

 
        while (num != _InterlockedCompareExchange(&gene.fmly32[kumi], mask.fmly32[kumi], num)) {

            std::this_thread::sleep_for(std::chrono::nanoseconds(100));
        };

 

        /// assert(room[curry.key].table[curry.buc].val == room[curry.key].table[curry.buc].key);

 
        return true;
    };

};

