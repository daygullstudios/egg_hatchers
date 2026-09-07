export default {
  fetch(): Response {
    return new Response("This local-only operator has no HTTP interface.", {
      status: 404,
    });
  },
} satisfies ExportedHandler;
