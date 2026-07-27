import {setGlobalOptions} from "firebase-functions/v2";

setGlobalOptions({maxInstances: 10});

export {
  acceptOffer,
  createProposal,
  ensureChat,
  rejectOffer,
  transitionServiceRequest,
} from "./callables.js";
export {
  onChatMessageCreated,
  onOfferAccepted,
  onOfferCreated,
  onReviewCreated,
  onServiceRequestUpdated,
  onServiceRequestWritten,
  onUserWritten,
} from "./projections.js";
