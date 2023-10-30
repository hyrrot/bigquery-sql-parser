import { PeggySyntaxError, parse } from './parser';

const text = 'SELECT 1 FROM t';

try {
    const sampleOutput = parse(text, { tracer: { trace: (t: any) => console.log(t) }  });
    console.log(sampleOutput);
} catch (ex: any) {
    console.log(ex);
    
    // Handle parsing error
    // [...]
}
