
declare class Ghost {
  constructor(directory: JSZipDirectory); // stable
  load(callback: (error: any) => void): void; // stable
  request(request: string, callback: (error: any, response: string) => void): void; // stable
  unload(callback: (error: any) => void): void; // stable
  descript: Descript; // stable
  directory: JSZipDirectory; // stable
  worker: Worker; // unstable
}


declare module Ghost {
  function createTransferable(directory: JSZipDirectory): {directory: {[filename: string]: ArrayBuffer; }; buffers: ArrayBuffer[]; }; // unstable
  function detectShiori(directory: JSZipDirectory): string; // unstable
}

declare module 'ghost' {
  var foo: typeof Ghost;
  module rsvp {
    export var Ghost: typeof foo;
  }
  export = rsvp;
}
