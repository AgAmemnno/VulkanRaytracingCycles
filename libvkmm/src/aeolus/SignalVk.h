#pragma once


#ifndef SIGNAL_VK_H
#define SIGNAL_VK_H
#include "pch_mm.h"
#include "working_mm.h"


namespace front {


    union SemaPhore {
        HANDLE     BlueLight;
        HANDLE     RedLight;
    };


    template<typename T, size_t N>
    class bonqueue {


        std::mutex guard_;
        std::condition_variable  sig_push;
        std::condition_variable  sig_pop;

    public:

        std::queue<T>     queue_;
        uint32_t              consume = 0;
        uint32_t              produce = 0;

        void reset() {
            consume = 0;
            produce = 0;
            while (queue_.size()) {
                T ret = std::move(queue_.front());
                log_warning(" bonqueue reset::  last of buds. [%d] \n ", (int)ret);
                queue_.pop();
            }
        };

        void push(T val) {
            ///static std::mutex guard_;
            ///static std::atomic_uint sigs = 0;
            std::unique_lock<std::mutex> lk(guard_);   /// {0}
            sig_pop.wait(lk, [this] {
                size_t size = queue_.size();
 
                if (size > N) {
                    ///log_warning("notify ============== = > notify signal   not_full   BonQueue Over limit.  %zu \n", size);
                    sig_push.notify_all();
                    return false;
                }
                return true;
             });

            queue_.push(std::move(val));
            if (val != -1)InterlockedExchangeAdd((long*)&produce, 1);
 

            //std::this_thread::sleep_for(std::chrono::nanoseconds(10));
 
            sig_push.notify_one();

            ///uint32_t nums = sigs.fetch_add(1);
 

        }

        T   nip() {
          
            std::unique_lock<std::mutex> lk(guard_);

            sig_push.wait(lk, [this] {
                ///uint32_t p = produce.load();
                ///uint32_t c = consume.load();
 
                return !queue_.empty();
                });

            T ret = std::move(queue_.front());
            queue_.pop();
            if (ret != -1)InterlockedExchangeAdd((long*)&consume, 1);
            sig_pop.notify_all();
 
            return ret;
        };

    };

    struct  Schedule {

        typedef   UINT16  tpCnt;
        typedef   UINT32  tpOrd;
        bool  escape;
        uint64_t escapeID;
        CRITICAL_SECTION gCs;
        const uint64_t seed = 0x19f093ab37c01fULL;


        struct {

            uint64_t     fmly64;
            uint32_t     fmly32[64];
            uint32_t* fmlyNext;/// [64 * 32] ;

        }gene, mask;
        void start();
        void stop();

        tpOrd wakeup(bool boss = false);
        void gohome(tpOrd  order);
        bool rollcall(uint64_t num);
        void EnsureEscapeEnd();

        tpOrd wakeup(tpCnt kumi, bool tyo = false);
        void gohome(tpCnt kumi, tpCnt sima);
        bool rollcall(tpCnt kumi, uint32_t num);

    };


  


    template<typename C1 = int64_t,typename C2 = int64_t,typename C3 = int64_t>
    struct hq_elem {

        typedef char type;
        C1                  compare;
        type            name = 'B';
        C2                compare2;
        C3                compare3;
       
        uintptr_t               data;
        std::any               any;
        std::shared_ptr<void>  shptr;

        //auto operator<=>(const D&) const = default;
        auto operator<=>(const hq_elem& that) const {
            if (auto comp = compare <=> that.compare; comp != 0) return comp;
            if (auto comp = name <=> that.name; comp != 0) return comp;
            if (auto comp = compare2 <=> that.compare2; comp != 0) return comp;
            return  compare3 <=> that.compare3;
        }

        //auto operator==(const D&) const = default;
        auto operator==(const hq_elem& that) const {
            if (auto comp = compare == that.compare; comp != 0) return comp;
            if (auto comp = name == that.name; comp != 0) return comp;
            if (auto comp = compare2 == that.compare2; comp != 0) return comp;
            return  compare3 == that.compare3;
        };


        template<typename T>
        explicit hq_elem(T&& cls) : compare(0), compare2(0), compare3(0) {};
        explicit  hq_elem(C1 comp, C2 comp2 = 0, C3 comp3 = 0) : compare(comp), compare2(comp2), compare3(comp3) {};

       explicit hq_elem() : compare(0), compare2(0), compare3(0) {};
       void setComp(C1 comp, C2 comp2 = 0, C3 comp3 = 0) { compare = comp, compare2 = comp2, compare3 = comp3; };


       template<typename T>
       void set(T&& cls) { 
          
            data = (uintptr_t)std::move(cls.sig); 
            ///any     = std::move(cls.sig);
            ///shptr = cls.sig;
            ///cls.sig = nullptr; 
       }

       /*
       hq_elem& operator=(hq_elem&& src) {
           data  = src.data;
           name = src.name;
           src.data = NULL;
           return *this;
       };
       hq_elem& operator=(hq_elem& src) {
           *this = src;
           return *this;
       };
       */
    };


    #define pv2id(p) (( (p)-pvt)%S) 
    #define id2pv(p) (( (p)+pvt)%S)

    template<size_t S>
    struct heapQ {

        typedef int64_t        c1type;
        typedef hq_elem<c1type> elemtype;

        size_t len  =  0;
        size_t pvt  = 0;
        elemtype elem[S];
        CRITICAL_SECTION                     critical;
        std::stringstream  debug;
        long                       entering = 0;
        ///heapQ(CRITICAL_SECTION * cs) :critical(cs){};
        heapQ() {
            
            InitializeCriticalSectionAndSpinCount(&critical, 8000);
        };
        ~heapQ() {
           
            DeleteCriticalSection(&critical);
        };

        template <class T, class... _Valty >
        bool push(T&& cls, _Valty&&... _Val) {


            EnterCriticalSection(&critical);
            if (len >= S) {
                LeaveCriticalSection(&critical);
                return false;
            }
          
            size_t pos  = (pvt + len) % S;
            elem[pos].set(std::forward<T>(cls));
            elem[pos].setComp(_Val ...);
         
            toRoot(pos);
            len++;
            LeaveCriticalSection(&critical);
        
            return true;

        };
        bool pop(elemtype& el) {

            EnterCriticalSection(&critical);
            
            if (len <= 0){
               LeaveCriticalSection(&critical);
               return false;
            }
            el = std::move(elem[pvt]);
            ///log_allo("Q pop  %p  len %u \n", el,len);
            if (len == 1) {
                len = 0;
                LeaveCriticalSection(&critical);
                return true;
            }
            elem[pvt] = std::move(elem[id2pv(len - 1)]);
            len--;
            toLeaf(pvt);
            ///log_allo("Q[%u]  toLeaf    len %u \n", pvt, len);
         
            LeaveCriticalSection(&critical);

            return true;
        }
        void print() {
        
#define  pushPRINT
#ifdef pushPRINT
            printf("################### pusher  ##################\n");
            int lev = 1;
            int levsize = 1;
            for (int i = 0; i < len; i++) {
                if (levsize <= i) {
                    lev *= 2; levsize += lev; printf("\n");
                }
                for (int j = 0; j < (64 - 10 * lev); j++)printf(" ");
                printf("  %lld  ", elem[id2pv(i)].compare);

            };
            printf("\n");
#endif
        }


        int toRoot(size_t pos)
        {
            size_t   ppos;
            elemtype newitem, parent;
            newitem = elem[pos];
            while (pos > 0) {
                ppos = id2pv(((pv2id(pos) - 1) >> 1));
                parent = elem[ppos];
                if (newitem < parent) {
                    parent   = std::move(elem[ppos]);
                    newitem = std::move(elem[pos]);
                    elem[ppos] = std::move(newitem);
                    elem[pos] = std::move(parent);
                    pos = ppos;
                    if (pos == 0)break;
                }
                else break;
            }
            return 0;
        };
        int toLeaf(size_t pos)
        {
            size_t  _pos, startpos, endpos, childpos;
            elemtype a, b;
            endpos = len - 1;
            _pos = startpos = pv2id(pos);
            while (true) {
                childpos = 2 * _pos + 1;
                if (childpos > len - 1) {
                    break;
                }
                a = elem[id2pv(childpos)];
                b = elem[id2pv(_pos)];
                if (a < b) {
                    elem[id2pv(childpos)] = std::move(b);
                    elem[id2pv(_pos)] = std::move(a);
                    _pos = childpos;
                }
                else break;
                
            };
            return 0;
        };

        template <class T, class... _Valty >
        bool pushmock(T&& cls, _Valty&&... _Val) {


            EnterCriticalSection(&critical);
            if (len >= S) {
                LeaveCriticalSection(&critical);
                return false;
            }
            InterlockedIncrement(&entering);
            size_t pos = (pvt + len) % S;
            elem[pos].set(std::forward<T>(cls));
            elem[pos].setComp(_Val ...);
            len++;
            //log_allo("push    pvt  %zu   len   %zu \n", pvt ,len);
            ///std::this_thread::sleep_for(std::chrono::milliseconds(1));
            ///debug << "push  " <<  pvt  << "   len  " << len << " enteringNum   " << entering << "\n";
            InterlockedDecrement(&entering);
            LeaveCriticalSection(&critical);
            return true;
        }
        void popmock(elemtype& el) {

            static  int cnt = 0;


            EnterCriticalSection(&critical);
            InterlockedIncrement(&entering);
            el = std::move(elem[pvt]);
            pvt = (pvt + 1) % S;
            len--;
            ///debug << "pop " <<pvt << "   len   "<< len <<" enteringNum   " << entering << "\n";
            InterlockedDecrement(&entering);
            LeaveCriticalSection(&critical);

            return;
        };


    };


    struct  CriticalHole {

        CRITICAL_SECTION                     whack;
        CONDITION_VARIABLE                  mole;
       
        long                                                   numMole;
        bool                                                 escape, on;
        void start();
        void stop();

        template<typename T, typename... Args>
        auto  enter(T&& f, Args... args) {

            EnterCriticalSection(&whack);

           

            while (!f(args ...) &&  !escape) {
                SleepConditionVariableCS(&mole, &whack, INFINITE);
            };

 
            if (escape)
            {
               
                LeaveCriticalSection(&whack);
                return false;
            };

            return true;

        };
        bool next();


        void EnsureEscapeEnd();
        void Whack(bool all = false);

    };


}

#endif