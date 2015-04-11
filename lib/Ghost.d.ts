interface JSZipDirectory { [filePath: string]: JSZipObject; };
interface Descript { [key: string]: string; };

declare class Ghost {
  constructor(directory: { [filePath: string]: ArrayBuffer; }); // stable
  load(callback: (error: any) => void): void; // stable
  request(request: string, callback: (error: any, response: string) => void): void; // stable
  unload(callback: (error: any) => void): void; // stable
  descript: Descript; // stable
  directory: { [filePath: string]: ArrayBuffer; }; // stable
  worker: Worker; // stable
}


declare module Ghost {
  function createTransferable(directory: { [filePath: string]: ArrayBuffer; }): {directory: {[filepath: string]: ArrayBuffer; }; buffers: ArrayBuffer[]; }; // stable
}

declare module 'ghost' {
  var foo: typeof Ghost;
  module rsvp {
    export var Ghost: typeof foo;
  }
  export = rsvp;
}
