export interface Comment {
  id: string;
  author: string;
  content: string;
  timestamp: number;
  isPending?: boolean;
}

export interface ValidationError {
  field: string;
  message: string;
}

export interface SubmitCommentResponse {
  success: boolean;
  comment?: Comment;
  errors?: ValidationError[];
}
