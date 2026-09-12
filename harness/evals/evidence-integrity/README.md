# evidence-integrity

Checks that a verification result says something true about the code it is attached to.

Three ways it can fail to. The source can change while the suite runs, so the suite never read
what is on disk when the result is written. A rerun can be interrupted, leaving an older pass
standing as though it were the current answer. And the Stop hook can read the document
differently from the drivers, accepting a closeout the drivers would refuse.
